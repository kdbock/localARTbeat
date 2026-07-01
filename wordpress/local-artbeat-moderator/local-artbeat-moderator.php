<?php
/**
 * Plugin Name: Local ARTbeat Moderator
 * Description: Private admin and moderator dashboard for Local ARTbeat analytics, captures, sponsorships, and event submissions.
 * Version: 0.4.0
 * Author: Local ARTbeat
 */

if (!defined('ABSPATH')) {
    exit;
}

final class Local_ARTbeat_Moderator_Plugin {
    private const VERSION = '0.4.0';
    private const OPTION_KEY = 'local_artbeat_moderator_options';
    private const NONCE_ACTION = 'local_artbeat_moderator_action';
    private const TOKEN_TRANSIENT = 'local_artbeat_firestore_access_token';

    public static function boot(): void {
        add_action('admin_menu', [self::class, 'register_menu']);
        add_action('admin_init', [self::class, 'register_settings']);
        add_action('admin_post_lab_moderator_action', [self::class, 'handle_action']);
    }

    public static function register_menu(): void {
        add_menu_page(
            'Local ARTbeat Admin',
            'Local ARTbeat',
            'manage_options',
            'local-artbeat-moderator',
            [self::class, 'render_admin_overview'],
            'dashicons-location-alt',
            58
        );

        add_submenu_page(
            'local-artbeat-moderator',
            'Overview',
            'Overview',
            'manage_options',
            'local-artbeat-moderator',
            [self::class, 'render_admin_overview']
        );

        add_submenu_page(
            'local-artbeat-moderator',
            'Paid Submission Moderation',
            'Paid Moderation',
            'manage_options',
            'local-artbeat-paid-moderation',
            [self::class, 'render_dashboard']
        );

        add_submenu_page(
            'local-artbeat-moderator',
            'Capture Review',
            'Capture Review',
            'manage_options',
            'local-artbeat-captures',
            [self::class, 'render_captures']
        );

        add_submenu_page(
            'local-artbeat-moderator',
            'Settings',
            'Settings',
            'manage_options',
            'local-artbeat-moderator-settings',
            [self::class, 'render_settings']
        );
    }

    public static function register_settings(): void {
        register_setting(
            'local_artbeat_moderator_settings',
            self::OPTION_KEY,
            [self::class, 'sanitize_options']
        );
    }

    public static function sanitize_options($input): array {
        $input = is_array($input) ? $input : [];
        $service_account_json = self::sanitize_service_account_input($input['service_account_json'] ?? '');
        return [
            'firebase_project_id' => sanitize_text_field($input['firebase_project_id'] ?? ''),
            'service_account_json' => $service_account_json,
            'facebook_page_id' => sanitize_text_field($input['facebook_page_id'] ?? ''),
            'facebook_page_access_token' => sanitize_text_field($input['facebook_page_access_token'] ?? ''),
        ];
    }

    public static function render_settings(): void {
        if (!current_user_can('manage_options')) {
            wp_die('You do not have permission to access this page.');
        }

        $options = self::options();
        $diagnostics = self::service_account_diagnostics($options['service_account_json']);
        ?>
        <div class="wrap">
            <h1>Local ARTbeat Moderator Settings</h1>
            <p><strong>Plugin version:</strong> <?php echo esc_html(self::VERSION); ?></p>
            <?php if ($diagnostics['message'] !== ''): ?>
                <div class="notice <?php echo $diagnostics['ok'] ? 'notice-success' : 'notice-warning'; ?>">
                    <p><?php echo esc_html($diagnostics['message']); ?></p>
                </div>
            <?php endif; ?>
            <form method="post" action="options.php">
                <?php settings_fields('local_artbeat_moderator_settings'); ?>
                <table class="form-table" role="presentation">
                    <tr>
                        <th scope="row"><label for="lab_firebase_project_id">Firebase project ID</label></th>
                        <td>
                            <input
                                id="lab_firebase_project_id"
                                class="regular-text"
                                name="<?php echo esc_attr(self::OPTION_KEY); ?>[firebase_project_id]"
                                value="<?php echo esc_attr($options['firebase_project_id']); ?>"
                                placeholder="wordnerd-artbeat"
                            />
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="lab_service_account_json">Service account JSON</label></th>
                        <td>
                            <textarea
                                id="lab_service_account_json"
                                class="large-text code"
                                rows="14"
                                name="<?php echo esc_attr(self::OPTION_KEY); ?>[service_account_json]"
                                placeholder='{"type":"service_account", ...}'
                            ><?php echo esc_textarea($options['service_account_json']); ?></textarea>
                            <p class="description">
                                Paste either the entire JSON file contents from Google Cloud or a base64-encoded copy of that JSON. Base64 is safer because WordPress cannot damage the private key line breaks while saving.
                            </p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="lab_facebook_page_id">Facebook Page ID</label></th>
                        <td>
                            <input
                                id="lab_facebook_page_id"
                                class="regular-text"
                                name="<?php echo esc_attr(self::OPTION_KEY); ?>[facebook_page_id]"
                                value="<?php echo esc_attr($options['facebook_page_id']); ?>"
                                placeholder="Facebook page ID"
                            />
                            <p class="description">Required only for posting captures directly as photo posts to a Facebook Page.</p>
                        </td>
                    </tr>
                    <tr>
                        <th scope="row"><label for="lab_facebook_page_access_token">Facebook Page access token</label></th>
                        <td>
                            <input
                                id="lab_facebook_page_access_token"
                                class="large-text code"
                                type="password"
                                name="<?php echo esc_attr(self::OPTION_KEY); ?>[facebook_page_access_token]"
                                value="<?php echo esc_attr($options['facebook_page_access_token']); ?>"
                                autocomplete="off"
                            />
                            <p class="description">Use a Page access token with permission to publish posts to your Local ARTbeat Facebook Page. Keep this private.</p>
                        </td>
                    </tr>
                </table>
                <?php submit_button('Save Settings'); ?>
            </form>
        </div>
        <?php
    }

    public static function render_admin_overview(): void {
        if (!current_user_can('manage_options')) {
            wp_die('You do not have permission to access this page.');
        }

        $notice = sanitize_text_field($_GET['lab_notice'] ?? '');
        $error = null;
        $captures = [];
        $users = [];
        $events = [];
        $sponsorships = [];

        try {
            $captures = self::recent_collection('captures', 250);
            $users = self::recent_collection('users', 250);
            $events = self::recent_collection('events', 250);
            $sponsorships = self::recent_collection('sponsorships', 250);
        } catch (Throwable $e) {
            $error = $e->getMessage();
        }

        $capture_stats = self::capture_stats($captures);
        $event_stats = self::status_counts($events, 'moderationStatus');
        $sponsorship_stats = self::status_counts($sponsorships, 'status');
        $top_locations = self::top_capture_locations($captures, 8);
        $recent_captures = array_slice($captures, 0, 6);
        ?>
        <div class="wrap local-artbeat-admin">
            <h1>Local ARTbeat Admin</h1>
            <p>Operational analytics for captures, community activity, paid submissions, and promotion opportunities. Plugin version <?php echo esc_html(self::VERSION); ?>.</p>

            <?php self::render_admin_styles(); ?>

            <?php if ($notice): ?>
                <div class="notice notice-success is-dismissible"><p><?php echo esc_html($notice); ?></p></div>
            <?php endif; ?>

            <?php if ($error): ?>
                <div class="notice notice-error"><p><?php echo esc_html($error); ?></p></div>
                <p>Fix the Firebase settings before reviewing analytics.</p>
            <?php else: ?>
                <div class="lab-metric-grid">
                    <?php self::metric_card('Captures', count($captures), $capture_stats['last_7_days'] . ' in last 7 days'); ?>
                    <?php self::metric_card('Public Captures', $capture_stats['public'], $capture_stats['approved'] . ' approved'); ?>
                    <?php self::metric_card('Users', count($users), self::active_user_count($users, 30) . ' active in last 30 days'); ?>
                    <?php self::metric_card('Pending Paid Reviews', (int) ($event_stats['paid_pending_review'] ?? 0) + (int) ($sponsorship_stats['pending'] ?? 0), 'events + sponsorships'); ?>
                    <?php self::metric_card('Flagged Captures', $capture_stats['flagged'], $capture_stats['reports'] . ' total reports'); ?>
                    <?php self::metric_card('Promoted Captures', $capture_stats['promoted'], 'marked for social use'); ?>
                </div>

                <div class="lab-columns">
                    <section>
                        <h2>Capture Health</h2>
                        <?php self::render_key_value_table([
                            'Approved' => $capture_stats['approved'],
                            'Pending' => $capture_stats['pending'],
                            'Rejected' => $capture_stats['rejected'],
                            'Private' => $capture_stats['private'],
                            'Total likes' => $capture_stats['likes'],
                            'Total shares' => $capture_stats['shares'],
                        ]); ?>
                    </section>

                    <section>
                        <h2>Paid Pipeline</h2>
                        <?php self::render_key_value_table([
                            'Event submissions pending' => $event_stats['paid_pending_review'] ?? 0,
                            'Events approved' => $event_stats['approved'] ?? 0,
                            'Sponsorships pending' => $sponsorship_stats['pending'] ?? 0,
                            'Sponsorships active' => $sponsorship_stats['active'] ?? 0,
                            'Sponsorships rejected' => $sponsorship_stats['rejected'] ?? 0,
                        ]); ?>
                    </section>
                </div>

                <div class="lab-columns">
                    <section>
                        <h2>Top Capture Locations</h2>
                        <?php self::render_key_value_table($top_locations ?: ['No location data yet' => 0]); ?>
                    </section>

                    <section>
                        <h2>Recent Captures For Social</h2>
                        <div class="lab-capture-strip">
                            <?php foreach ($recent_captures as $row): ?>
                                <?php self::render_capture_tile($row, false); ?>
                            <?php endforeach; ?>
                        </div>
                        <p><a class="button button-primary" href="<?php echo esc_url(admin_url('admin.php?page=local-artbeat-captures')); ?>">Open Capture Review</a></p>
                    </section>
                </div>
            <?php endif; ?>
        </div>
        <?php
    }

    public static function render_dashboard(): void {
        if (!current_user_can('manage_options')) {
            wp_die('You do not have permission to access this page.');
        }

        $notice = sanitize_text_field($_GET['lab_notice'] ?? '');
        $error = null;
        $sponsorships = [];
        $events = [];
        $edit_suggestions = [];

        try {
            $sponsorships = self::query_collection('sponsorships', 'status', 'pending');
            $events = self::query_collection('events', 'moderationStatus', 'paid_pending_review');
            $edit_suggestions = self::query_collection('captureEditSuggestions', 'status', 'pending');
        } catch (Throwable $e) {
            $error = $e->getMessage();
        }

        ?>
        <div class="wrap">
            <h1>Local ARTbeat Moderator</h1>
            <p>Approve or reject paid submissions. Keep this dashboard private. Plugin version <?php echo esc_html(self::VERSION); ?>.</p>

            <?php if ($notice): ?>
                <div class="notice notice-success is-dismissible"><p><?php echo esc_html($notice); ?></p></div>
            <?php endif; ?>

            <?php if ($error): ?>
                <div class="notice notice-error"><p><?php echo esc_html($error); ?></p></div>
            <?php endif; ?>

            <?php if (!$error): ?>
                <h2>Sponsorship Inventory</h2>
                <?php self::render_sponsorship_inventory_specs(); ?>

                <hr />

                <h2>Pending Sponsorships</h2>
                <?php self::render_sponsorship_table($sponsorships); ?>

                <hr />

                <h2>Pending Event Submissions</h2>
                <?php self::render_event_table($events); ?>

                <hr />

                <h2>Pending Capture Edit Suggestions</h2>
                <?php self::render_capture_edit_suggestion_table($edit_suggestions); ?>
            <?php else: ?>
                <p>Fix the Firebase settings before reviewing submissions.</p>
            <?php endif; ?>
        </div>
        <?php
    }

    public static function render_captures(): void {
        if (!current_user_can('manage_options')) {
            wp_die('You do not have permission to access this page.');
        }

        $notice = sanitize_text_field($_GET['lab_notice'] ?? '');
        $filter = sanitize_key($_GET['capture_filter'] ?? 'recent');
        $error = null;
        $captures = [];

        try {
            $captures = self::recent_collection('captures', 120);
        } catch (Throwable $e) {
            $error = $e->getMessage();
        }

        if (!$error) {
            $captures = self::filter_captures($captures, $filter);
        }

        ?>
        <div class="wrap local-artbeat-admin">
            <h1>Capture Review</h1>
            <p>Review user captures, find social-ready discoveries, and track which captures have already been used for promotion. Plugin version <?php echo esc_html(self::VERSION); ?>.</p>

            <?php self::render_admin_styles(); ?>

            <?php if ($notice): ?>
                <div class="notice notice-success is-dismissible"><p><?php echo esc_html($notice); ?></p></div>
            <?php endif; ?>

            <?php if ($error): ?>
                <div class="notice notice-error"><p><?php echo esc_html($error); ?></p></div>
            <?php else: ?>
                <p class="subsubsub">
                    <a href="<?php echo esc_url(admin_url('admin.php?page=local-artbeat-captures&capture_filter=recent')); ?>" class="<?php echo $filter === 'recent' ? 'current' : ''; ?>">Recent</a> |
                    <a href="<?php echo esc_url(admin_url('admin.php?page=local-artbeat-captures&capture_filter=public')); ?>" class="<?php echo $filter === 'public' ? 'current' : ''; ?>">Public</a> |
                    <a href="<?php echo esc_url(admin_url('admin.php?page=local-artbeat-captures&capture_filter=flagged')); ?>" class="<?php echo $filter === 'flagged' ? 'current' : ''; ?>">Flagged</a> |
                    <a href="<?php echo esc_url(admin_url('admin.php?page=local-artbeat-captures&capture_filter=promoted')); ?>" class="<?php echo $filter === 'promoted' ? 'current' : ''; ?>">Promoted</a> |
                    <a href="<?php echo esc_url(admin_url('admin.php?page=local-artbeat-captures&capture_filter=social')); ?>" class="<?php echo $filter === 'social' ? 'current' : ''; ?>">Social Candidates</a>
                </p>
                <div style="clear:both"></div>

                <?php if (!$captures): ?>
                    <p>No captures found for this filter.</p>
                <?php else: ?>
                    <div class="lab-capture-grid">
                        <?php foreach ($captures as $row): ?>
                            <?php self::render_capture_tile($row, true); ?>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            <?php endif; ?>
        </div>
        <?php
    }

    private static function render_sponsorship_table(array $rows): void {
        if (!$rows) {
            echo '<p>No pending sponsorships.</p>';
            return;
        }

        echo '<table class="widefat striped">';
        echo '<thead><tr><th>Business</th><th>Tier</th><th>Contact</th><th>Payment</th><th>Placement</th><th>Notes</th><th>Actions</th></tr></thead><tbody>';

        foreach ($rows as $row) {
            $fields = $row['fields'];
            $id = $row['id'];
            echo '<tr>';
            echo '<td><strong>' . esc_html(self::field($fields, 'businessName')) . '</strong><br />' . esc_html(self::field($fields, 'businessAddress')) . '</td>';
            echo '<td>' . esc_html(self::field($fields, 'tier')) . '</td>';
            echo '<td>' . esc_html(self::field($fields, 'contactEmail')) . '<br />' . esc_html(self::field($fields, 'phone')) . '</td>';
            echo '<td>' . esc_html(self::field($fields, 'paymentStatus')) . '<br /><code>' . esc_html(self::field($fields, 'iapPurchaseId')) . '</code></td>';
            echo '<td>' . esc_html(implode(', ', self::array_field($fields, 'placementKeys'))) . '</td>';
            echo '<td>' . esc_html(self::field($fields, 'brandingNotes') ?: self::field($fields, 'additionalNotes')) . '</td>';
            echo '<td>' . self::action_form('sponsorship', $id, ['approve_sponsorship' => 'Approve', 'reject_sponsorship' => 'Reject', 'expire_sponsorship' => 'Expire']) . '</td>';
            echo '</tr>';
        }

        echo '</tbody></table>';
    }

    private static function render_event_table(array $rows): void {
        if (!$rows) {
            echo '<p>No pending event submissions.</p>';
            return;
        }

        echo '<table class="widefat striped">';
        echo '<thead><tr><th>Event</th><th>Date</th><th>Location</th><th>Contact</th><th>Payment</th><th>Actions</th></tr></thead><tbody>';

        foreach ($rows as $row) {
            $fields = $row['fields'];
            $id = $row['id'];
            $metadata = self::map_field($fields, 'metadata');
            echo '<tr>';
            echo '<td><strong>' . esc_html(self::field($fields, 'title')) . '</strong><br />' . esc_html(self::field($fields, 'description')) . '</td>';
            echo '<td>' . esc_html(self::timestamp_field($fields, 'dateTime')) . '</td>';
            echo '<td>' . esc_html(self::field($fields, 'location')) . '</td>';
            echo '<td>' . esc_html(self::field($fields, 'contactEmail')) . '<br />' . esc_html(self::field($fields, 'contactPhone')) . '</td>';
            echo '<td>' . esc_html(self::map_value($metadata, 'submissionPaymentStatus')) . '<br /><code>' . esc_html(self::map_value($metadata, 'submissionPurchaseId')) . '</code></td>';
            echo '<td>' . self::action_form('event', $id, ['approve_event' => 'Approve', 'reject_event' => 'Reject']) . '</td>';
            echo '</tr>';
        }

        echo '</tbody></table>';
    }

    private static function render_capture_edit_suggestion_table(array $rows): void {
        if (!$rows) {
            echo '<p>No pending capture edit suggestions.</p>';
            return;
        }

        echo '<table class="widefat striped">';
        echo '<thead><tr><th>Capture</th><th>Suggested changes</th><th>Submitted by</th><th>Note</th><th>Actions</th></tr></thead><tbody>';

        foreach ($rows as $row) {
            $fields = $row['fields'];
            $id = $row['id'];
            $changes = self::map_field($fields, 'proposedChanges');
            $original = self::map_field($fields, 'originalValues');
            $image = self::field($fields, 'captureImageUrl');
            echo '<tr>';
            echo '<td>';
            if ($image !== '') {
                echo '<a href="' . esc_url($image) . '" target="_blank" rel="noopener"><img src="' . esc_url($image) . '" alt="" style="width:96px;height:72px;object-fit:cover;border-radius:6px;display:block;margin-bottom:6px" /></a>';
            }
            echo '<strong>' . esc_html(self::field($fields, 'captureTitle') ?: self::map_value($original, 'title') ?: 'Untitled capture') . '</strong><br />';
            echo '<code>' . esc_html(self::field($fields, 'captureId')) . '</code><br />';
            echo esc_html(self::field($fields, 'captureLocationName'));
            echo '</td>';
            echo '<td>';
            if (!$changes) {
                echo '<em>No field changes, note only.</em>';
            } else {
                echo '<ul style="margin:0">';
                foreach ($changes as $key => $value) {
                    echo '<li><strong>' . esc_html($key) . ':</strong> ';
                    echo '<span style="color:#646970">' . esc_html(self::map_value($original, $key)) . '</span>';
                    echo ' → ' . esc_html(self::field([$key => $value], $key));
                    echo '</li>';
                }
                echo '</ul>';
            }
            echo '</td>';
            echo '<td>' . esc_html(self::field($fields, 'submittedByName')) . '<br />' . esc_html(self::field($fields, 'submittedByEmail')) . '<br />' . esc_html(self::format_datetime(self::timestamp_field($fields, 'createdAt'))) . '</td>';
            echo '<td>' . esc_html(self::field($fields, 'note')) . '</td>';
            echo '<td>' . self::action_form('capture_edit', $id, ['approve_capture_edit' => 'Apply Approved Edits', 'reject_capture_edit' => 'Reject']) . '</td>';
            echo '</tr>';
        }

        echo '</tbody></table>';
    }

    private static function render_sponsorship_inventory_specs(): void {
        $rows = [
            ['Sponsor This Spot', 'capture_detail_banner', 'Capture detail and map capture cards for a nearby artwork', '$99/month', '1200x300 PNG/JPG/GIF, 4:1 ratio; optional 1080x1080 square backup', 'Local business near a specific piece of art'],
            ['Radar Zone Sponsor', 'discover_radar_banner', 'Instant radar and discovery screens while users scan nearby art', '$149/month', '1200x300 PNG/JPG/GIF, 4:1 ratio; animated GIF under 3 MB', 'Businesses near a walkable scan area or ZIP code'],
            ['Town Feed Sponsor', 'community_feed_banner', 'Community feed placement for a ZIP/town', '$199/month', '1200x628 JPG/PNG or 1080x1080 square; short headline and destination URL', 'Townwide awareness campaign'],
            ['Art Walk Sponsor', 'art_walk_header', 'Guided art walk header/detail placement', '$249/month', '1600x500 JPG/PNG/GIF, 3.2:1 ratio; route partner copy', 'Route partner, coffee stop, venue, gallery, visitor center'],
        ];

        echo '<table class="widefat striped">';
        echo '<thead><tr><th>Sellable package</th><th>Placement key</th><th>Where it appears</th><th>Base price</th><th>Recommended creative</th><th>Best fit</th></tr></thead><tbody>';
        foreach ($rows as $row) {
            echo '<tr>';
            foreach ($row as $cell) {
                echo '<td>' . esc_html($cell) . '</td>';
            }
            echo '</tr>';
        }
        echo '</tbody></table>';
        echo '<p class="description">Every placement requires moderator approval before it goes live. Approved records should include a destination URL, business name, image URL, placement key, date range, optional latitude/longitude radius targeting, and review notes. GIFs are allowed for rotating creative when they stay under the listed size guidance.</p>';
    }

    private static function action_form(string $type, string $id, array $actions): string {
        ob_start();
        ?>
        <form method="post" action="<?php echo esc_url(admin_url('admin-post.php')); ?>" style="min-width:220px">
            <?php wp_nonce_field(self::NONCE_ACTION); ?>
            <input type="hidden" name="action" value="lab_moderator_action" />
            <input type="hidden" name="record_type" value="<?php echo esc_attr($type); ?>" />
            <input type="hidden" name="record_id" value="<?php echo esc_attr($id); ?>" />
            <input type="hidden" name="return_page" value="<?php echo esc_attr($type === 'capture' ? 'local-artbeat-captures' : 'local-artbeat-paid-moderation'); ?>" />
            <p>
                <textarea name="notes" rows="2" class="large-text" placeholder="Review notes"></textarea>
            </p>
            <?php foreach ($actions as $action => $label): ?>
                <button class="button" type="submit" name="moderator_action" value="<?php echo esc_attr($action); ?>">
                    <?php echo esc_html($label); ?>
                </button>
            <?php endforeach; ?>
        </form>
        <?php
        return (string) ob_get_clean();
    }

    private static function render_admin_styles(): void {
        static $rendered = false;
        if ($rendered) {
            return;
        }
        $rendered = true;
        ?>
        <style>
            .local-artbeat-admin .lab-metric-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin:18px 0}
            .local-artbeat-admin .lab-card,.local-artbeat-admin .lab-capture-card{background:#fff;border:1px solid #dcdcde;border-radius:8px;padding:14px}
            .local-artbeat-admin .lab-card strong{display:block;font-size:28px;line-height:1.1;margin:6px 0;color:#1d2327}
            .local-artbeat-admin .lab-card span{color:#646970}
            .local-artbeat-admin .lab-columns{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:18px;margin-top:18px}
            .local-artbeat-admin .lab-capture-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px;margin-top:16px}
            .local-artbeat-admin .lab-capture-strip{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px}
            .local-artbeat-admin .lab-capture-card img{width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:6px;background:#f0f0f1}
            .local-artbeat-admin .lab-capture-meta{color:#646970;font-size:12px;margin:8px 0}
            .local-artbeat-admin .lab-caption{width:100%;min-height:92px;font-family:monospace;font-size:12px}
            .local-artbeat-admin .lab-chip{display:inline-block;border:1px solid #c3c4c7;border-radius:999px;padding:2px 8px;margin:2px 2px 2px 0;background:#f6f7f7;font-size:12px}
            .local-artbeat-admin .lab-actions .button{margin:0 4px 4px 0}
            .local-artbeat-admin .lab-share-row{display:flex;flex-wrap:wrap;gap:6px;margin:10px 0}
        </style>
        <script>
            document.addEventListener('click', function (event) {
                var button = event.target.closest('[data-lab-copy-caption]');
                if (!button) {
                    return;
                }
                var target = document.getElementById(button.getAttribute('data-lab-copy-caption'));
                if (!target) {
                    return;
                }
                target.select();
                target.setSelectionRange(0, target.value.length);
                if (navigator.clipboard && navigator.clipboard.writeText) {
                    navigator.clipboard.writeText(target.value);
                } else {
                    document.execCommand('copy');
                }
                button.textContent = 'Copied caption';
                setTimeout(function () {
                    button.textContent = 'Copy Caption';
                }, 1600);
            });
        </script>
        <?php
    }

    private static function metric_card(string $label, $value, string $detail): void {
        echo '<div class="lab-card"><span>' . esc_html($label) . '</span><strong>' . esc_html((string) $value) . '</strong><span>' . esc_html($detail) . '</span></div>';
    }

    private static function render_key_value_table(array $rows): void {
        echo '<table class="widefat striped"><tbody>';
        foreach ($rows as $label => $value) {
            echo '<tr><th scope="row">' . esc_html((string) $label) . '</th><td>' . esc_html((string) $value) . '</td></tr>';
        }
        echo '</tbody></table>';
    }

    private static function render_capture_tile(array $row, bool $show_actions): void {
        $fields = $row['fields'];
        $id = $row['id'];
        $title = self::first_nonempty([
            self::field($fields, 'title'),
            self::field($fields, 'artistName'),
            'Untitled capture',
        ]);
        $image = self::first_nonempty([self::field($fields, 'thumbnailUrl'), self::field($fields, 'imageUrl')]);
        $location = self::capture_location_label($fields);
        $maps_url = self::capture_maps_url($fields);
        $status = self::field($fields, 'status') ?: 'unknown';
        $is_public = self::bool_field($fields, 'isPublic');
        $is_flagged = self::bool_field($fields, 'isFlagged');
        $promotion = self::field($fields, 'adminPromotionStatus') ?: 'not_promoted';
        $engagement = self::map_field($fields, 'engagementStats');
        $caption = self::social_caption($fields);
        $caption_id = 'lab-caption-' . preg_replace('/[^A-Za-z0-9_-]/', '', $id);
        $share_url = self::facebook_share_url($fields, $caption);

        echo '<article class="lab-capture-card">';
        if ($image) {
            echo '<a href="' . esc_url($image) . '" target="_blank" rel="noopener"><img src="' . esc_url($image) . '" alt="" loading="lazy" /></a>';
        } else {
            echo '<div style="aspect-ratio:4/3;background:#f0f0f1;border-radius:6px;display:flex;align-items:center;justify-content:center;color:#646970">No image</div>';
        }
        echo '<h3>' . esc_html($title) . '</h3>';
        echo '<p class="lab-capture-meta">';
        if ($maps_url !== '') {
            echo '<a href="' . esc_url($maps_url) . '" target="_blank" rel="noopener">' . esc_html($location) . '</a>';
        } else {
            echo esc_html($location);
        }
        echo '<br />' . esc_html(self::format_datetime(self::timestamp_field($fields, 'createdAt'))) . '<br />By ' . esc_html(self::first_nonempty([self::field($fields, 'userName'), self::field($fields, 'userHandle'), self::field($fields, 'userId')])) . '</p>';
        echo '<p>';
        echo '<span class="lab-chip">status: ' . esc_html($status) . '</span>';
        echo '<span class="lab-chip">' . esc_html($is_public ? 'public' : 'private') . '</span>';
        if ($is_flagged) {
            echo '<span class="lab-chip">flagged</span>';
        }
        if ($promotion === 'promoted') {
            echo '<span class="lab-chip">promoted</span>';
        }
        echo '</p>';
        echo '<p class="lab-capture-meta">Likes ' . esc_html(self::map_int($engagement, 'likeCount')) . ' · Comments ' . esc_html(self::map_int($engagement, 'commentCount')) . ' · Shares ' . esc_html(self::map_int($engagement, 'shareCount')) . ' · Reports ' . esc_html(self::int_field($fields, 'reportCount')) . '</p>';
        echo '<textarea id="' . esc_attr($caption_id) . '" class="lab-caption" readonly>' . esc_textarea($caption) . '</textarea>';
        echo '<div class="lab-share-row">';
        if ($share_url !== '') {
            echo '<a class="button" href="' . esc_url($image) . '" target="_blank" rel="noopener">Open Image</a>';
            echo '<a class="button" href="' . esc_url($share_url) . '" target="_blank" rel="noopener">Open Facebook Share</a>';
        }
        echo '<button type="button" class="button" data-lab-copy-caption="' . esc_attr($caption_id) . '">Copy Caption</button>';
        echo '</div>';

        if ($show_actions) {
            echo '<div class="lab-actions">';
            echo self::action_form('capture', $id, [
                'mark_capture_promoted' => 'Mark Promoted',
                'clear_capture_promoted' => 'Clear Promoted',
                'publish_capture_facebook' => 'Post Photo to Facebook Page',
                'approve_capture' => 'Approve Public',
                'flag_capture' => 'Flag',
                'reject_capture' => 'Reject',
            ]);
            echo '</div>';
        }

        echo '</article>';
    }

    public static function handle_action(): void {
        if (!current_user_can('manage_options')) {
            wp_die('You do not have permission to do this.');
        }

        check_admin_referer(self::NONCE_ACTION);

        $action = sanitize_key($_POST['moderator_action'] ?? '');
        $type = sanitize_key($_POST['record_type'] ?? '');
        $id = sanitize_text_field(wp_unslash($_POST['record_id'] ?? ''));
        $notes = sanitize_textarea_field(wp_unslash($_POST['notes'] ?? ''));
        $return_page = sanitize_key($_POST['return_page'] ?? 'local-artbeat-paid-moderation');

        try {
            if ($type === 'sponsorship') {
                self::handle_sponsorship_action($action, $id, $notes);
            } elseif ($type === 'event') {
                self::handle_event_action($action, $id, $notes);
            } elseif ($type === 'capture') {
                self::handle_capture_action($action, $id, $notes);
            } elseif ($type === 'capture_edit') {
                self::handle_capture_edit_action($action, $id, $notes);
            } else {
                throw new RuntimeException('Unknown record type.');
            }

            $message = 'Updated successfully.';
        } catch (Throwable $e) {
            $message = 'Error: ' . $e->getMessage();
        }

        wp_safe_redirect(add_query_arg(
            'lab_notice',
            rawurlencode($message),
            admin_url('admin.php?page=' . rawurlencode($return_page))
        ));
        exit;
    }

    private static function handle_sponsorship_action(string $action, string $id, string $notes): void {
        $now = gmdate('c');
        $reviewer = self::reviewer_label();
        $fields = [
            'reviewedAt' => ['timestampValue' => $now],
            'reviewedBy' => ['stringValue' => $reviewer],
            'moderationNotes' => ['stringValue' => $notes],
        ];

        if ($action === 'approve_sponsorship') {
            $existing = self::get_document('sponsorships', $id);
            $durationSeconds = self::sponsorship_duration_seconds($existing['fields'] ?? []);
            $fields['status'] = ['stringValue' => 'active'];
            $fields['paymentFollowUpStatus'] = ['stringValue' => 'paid_approved_active'];
            $fields['startDate'] = ['timestampValue' => $now];
            $fields['endDate'] = ['timestampValue' => gmdate('c', time() + $durationSeconds)];
        } elseif ($action === 'reject_sponsorship') {
            $fields['status'] = ['stringValue' => 'rejected'];
            $fields['paymentFollowUpStatus'] = ['stringValue' => 'rejected_review_refund_required'];
        } elseif ($action === 'expire_sponsorship') {
            $fields['status'] = ['stringValue' => 'expired'];
            $fields['endDate'] = ['timestampValue' => $now];
        } else {
            throw new RuntimeException('Unknown sponsorship action.');
        }

        self::patch_document('sponsorships', $id, $fields);
    }

    private static function handle_event_action(string $action, string $id, string $notes): void {
        $fields = [
            'lastModerated' => ['timestampValue' => gmdate('c')],
            'reviewedBy' => ['stringValue' => self::reviewer_label()],
            'reviewNotes' => ['stringValue' => $notes],
        ];

        if ($action === 'approve_event') {
            $fields['moderationStatus'] = ['stringValue' => 'approved'];
            $fields['isPublic'] = ['booleanValue' => true];
        } elseif ($action === 'reject_event') {
            $fields['moderationStatus'] = ['stringValue' => 'rejected'];
            $fields['isPublic'] = ['booleanValue' => false];
        } else {
            throw new RuntimeException('Unknown event action.');
        }

        self::patch_document('events', $id, $fields);
    }

    private static function handle_capture_action(string $action, string $id, string $notes): void {
        $fields = [
            'adminReviewedAt' => ['timestampValue' => gmdate('c')],
            'adminReviewedBy' => ['stringValue' => self::reviewer_label()],
        ];

        if ($notes !== '') {
            $fields['adminNotes'] = ['stringValue' => $notes];
        }

        if ($action === 'mark_capture_promoted') {
            $fields['adminPromotionStatus'] = ['stringValue' => 'promoted'];
            $fields['promotedAt'] = ['timestampValue' => gmdate('c')];
            $fields['promotedBy'] = ['stringValue' => self::reviewer_label()];
        } elseif ($action === 'clear_capture_promoted') {
            $fields['adminPromotionStatus'] = ['stringValue' => 'not_promoted'];
        } elseif ($action === 'publish_capture_facebook') {
            $existing = self::get_document('captures', $id);
            $capture_fields = $existing['fields'] ?? [];
            $facebook_post_id = self::publish_capture_to_facebook_page($capture_fields, $notes);
            $fields['adminPromotionStatus'] = ['stringValue' => 'promoted'];
            $fields['promotedAt'] = ['timestampValue' => gmdate('c')];
            $fields['promotedBy'] = ['stringValue' => self::reviewer_label()];
            $fields['socialPromotionChannel'] = ['stringValue' => 'facebook'];
            $fields['facebookPostId'] = ['stringValue' => $facebook_post_id];
        } elseif ($action === 'flag_capture') {
            $fields['isFlagged'] = ['booleanValue' => true];
            $fields['adminFlaggedAt'] = ['timestampValue' => gmdate('c')];
        } elseif ($action === 'approve_capture') {
            $fields['status'] = ['stringValue' => 'approved'];
            $fields['isPublic'] = ['booleanValue' => true];
            $fields['isFlagged'] = ['booleanValue' => false];
        } elseif ($action === 'reject_capture') {
            $fields['status'] = ['stringValue' => 'rejected'];
            $fields['isPublic'] = ['booleanValue' => false];
            $fields['moderationNotes'] = ['stringValue' => $notes];
        } else {
            throw new RuntimeException('Unknown capture action.');
        }

        self::patch_document('captures', $id, $fields);
    }

    private static function handle_capture_edit_action(string $action, string $id, string $notes): void {
        $suggestion = self::get_document('captureEditSuggestions', $id);
        $fields = $suggestion['fields'] ?? [];
        $capture_id = self::field($fields, 'captureId');
        if ($capture_id === '') {
            throw new RuntimeException('Edit suggestion is missing captureId.');
        }

        $review_fields = [
            'reviewedAt' => ['timestampValue' => gmdate('c')],
            'reviewedBy' => ['stringValue' => self::reviewer_label()],
            'moderationNotes' => ['stringValue' => $notes],
            'updatedAt' => ['timestampValue' => gmdate('c')],
        ];

        if ($action === 'approve_capture_edit') {
            $changes = self::map_field($fields, 'proposedChanges');
            $capture_fields = [
                'adminReviewedAt' => ['timestampValue' => gmdate('c')],
                'adminReviewedBy' => ['stringValue' => self::reviewer_label()],
                'lastSuggestedEditAppliedAt' => ['timestampValue' => gmdate('c')],
                'lastSuggestedEditId' => ['stringValue' => $id],
            ];
            foreach (['title', 'artistName', 'description', 'locationName', 'artType'] as $allowed_field) {
                $value = self::map_value($changes, $allowed_field);
                if ($value !== '') {
                    $capture_fields[$allowed_field] = ['stringValue' => $value];
                }
            }
            if (count($capture_fields) <= 4 && $notes === '') {
                throw new RuntimeException('No proposed field changes to apply. Reject or add notes instead.');
            }
            self::patch_document('captures', $capture_id, $capture_fields);
            $review_fields['status'] = ['stringValue' => 'approved'];
            $review_fields['appliedAt'] = ['timestampValue' => gmdate('c')];
        } elseif ($action === 'reject_capture_edit') {
            $review_fields['status'] = ['stringValue' => 'rejected'];
        } else {
            throw new RuntimeException('Unknown capture edit action.');
        }

        self::patch_document('captureEditSuggestions', $id, $review_fields);
    }

    private static function sponsorship_duration_seconds(array $fields): int {
        $start = strtotime(self::timestamp_field($fields, 'startDate'));
        $end = strtotime(self::timestamp_field($fields, 'endDate'));
        if ($start && $end && $end > $start) {
            return max(86400, $end - $start);
        }
        return 30 * 86400;
    }

    private static function query_collection(string $collection, string $field, string $value): array {
        $body = [
            'structuredQuery' => [
                'from' => [['collectionId' => $collection]],
                'where' => [
                    'fieldFilter' => [
                        'field' => ['fieldPath' => $field],
                        'op' => 'EQUAL',
                        'value' => ['stringValue' => $value],
                    ],
                ],
                'limit' => 50,
            ],
        ];

        $response = self::firestore_request('POST', ':runQuery', $body);
        $rows = [];
        foreach ($response as $item) {
            if (!isset($item['document'])) {
                continue;
            }
            $document = $item['document'];
            $rows[] = [
                'id' => basename($document['name']),
                'fields' => $document['fields'] ?? [],
            ];
        }

        usort($rows, function ($a, $b) {
            $aTime = strtotime(self::timestamp_field($a['fields'], 'createdAt')) ?: 0;
            $bTime = strtotime(self::timestamp_field($b['fields'], 'createdAt')) ?: 0;
            return $bTime <=> $aTime;
        });

        return $rows;
    }

    private static function recent_collection(string $collection, int $limit = 100): array {
        $body = [
            'structuredQuery' => [
                'from' => [['collectionId' => $collection]],
                'orderBy' => [
                    [
                        'field' => ['fieldPath' => 'createdAt'],
                        'direction' => 'DESCENDING',
                    ],
                ],
                'limit' => $limit,
            ],
        ];

        try {
            return self::rows_from_run_query(self::firestore_request('POST', ':runQuery', $body));
        } catch (Throwable $e) {
            $response = self::firestore_request('GET', '/' . rawurlencode($collection) . '?pageSize=' . max(1, min($limit, 300)));
            $rows = [];
            foreach (($response['documents'] ?? []) as $document) {
                $rows[] = [
                    'id' => basename($document['name']),
                    'fields' => $document['fields'] ?? [],
                ];
            }
            usort($rows, function ($a, $b) {
                $aTime = strtotime(self::timestamp_field($a['fields'], 'createdAt')) ?: 0;
                $bTime = strtotime(self::timestamp_field($b['fields'], 'createdAt')) ?: 0;
                return $bTime <=> $aTime;
            });
            return $rows;
        }
    }

    private static function rows_from_run_query(array $response): array {
        $rows = [];
        foreach ($response as $item) {
            if (!isset($item['document'])) {
                continue;
            }
            $document = $item['document'];
            $rows[] = [
                'id' => basename($document['name']),
                'fields' => $document['fields'] ?? [],
            ];
        }
        return $rows;
    }

    private static function get_document(string $collection, string $id): array {
        return self::firestore_request('GET', '/' . rawurlencode($collection) . '/' . rawurlencode($id));
    }

    private static function patch_document(string $collection, string $id, array $fields): void {
        $query = [];
        foreach (array_keys($fields) as $field) {
            $query[] = 'updateMask.fieldPaths=' . rawurlencode($field);
        }
        $path = '/' . rawurlencode($collection) . '/' . rawurlencode($id) . '?' . implode('&', $query);
        self::firestore_request('PATCH', $path, ['fields' => $fields]);
    }

    private static function firestore_request(string $method, string $path, ?array $body = null) {
        $project = self::project_id();
        $base = 'https://firestore.googleapis.com/v1/projects/' . rawurlencode($project) . '/databases/(default)/documents';
        $url = $base . $path;

        $args = [
            'method' => $method,
            'timeout' => 20,
            'headers' => [
                'Authorization' => 'Bearer ' . self::access_token(),
                'Content-Type' => 'application/json',
            ],
        ];
        if ($body !== null) {
            $args['body'] = wp_json_encode($body);
        }

        $response = wp_remote_request($url, $args);
        if (is_wp_error($response)) {
            throw new RuntimeException($response->get_error_message());
        }

        $code = (int) wp_remote_retrieve_response_code($response);
        $raw = wp_remote_retrieve_body($response);
        $decoded = $raw !== '' ? json_decode($raw, true) : [];

        if ($code < 200 || $code >= 300) {
            $message = is_array($decoded) && isset($decoded['error']['message'])
                ? $decoded['error']['message']
                : 'Firestore request failed.';
            throw new RuntimeException($message);
        }

        return $decoded;
    }

    private static function access_token(): string {
        $cached = get_transient(self::TOKEN_TRANSIENT);
        if (is_string($cached) && $cached !== '') {
            return $cached;
        }

        $account = self::service_account();
        $now = time();
        $header = self::base64url(wp_json_encode(['alg' => 'RS256', 'typ' => 'JWT']));
        $claim = self::base64url(wp_json_encode([
            'iss' => $account['client_email'],
            'scope' => 'https://www.googleapis.com/auth/datastore',
            'aud' => $account['token_uri'],
            'iat' => $now,
            'exp' => $now + 3600,
        ]));

        $unsigned = $header . '.' . $claim;
        $signature = '';
        if (!function_exists('openssl_sign') || !function_exists('openssl_pkey_get_private')) {
            throw new RuntimeException('PHP OpenSSL extension is not available on this WordPress server.');
        }

        $key_resource = self::load_private_key($account['private_key']);
        if ($key_resource === false) {
            $openssl_error = self::openssl_error_summary();
            $summary = self::credential_storage_summary(self::options()['service_account_json']);
            $key_summary = self::private_key_summary($account['private_key']);
            throw new RuntimeException('Could not load Firebase service-account private_key. Re-paste the base64 service-account value, not the raw JSON.' . $summary . $key_summary . $openssl_error);
        }

        $ok = openssl_sign($unsigned, $signature, $key_resource, OPENSSL_ALGO_SHA256);
        if (!$ok) {
            throw new RuntimeException('Could not sign Firebase service-account JWT.');
        }

        $jwt = $unsigned . '.' . self::base64url($signature);
        $response = wp_remote_post($account['token_uri'], [
            'timeout' => 20,
            'body' => [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
                'assertion' => $jwt,
            ],
        ]);

        if (is_wp_error($response)) {
            throw new RuntimeException($response->get_error_message());
        }

        $decoded = json_decode(wp_remote_retrieve_body($response), true);
        if (!is_array($decoded) || empty($decoded['access_token'])) {
            throw new RuntimeException('Could not obtain Firebase access token.');
        }

        $ttl = max(60, ((int) ($decoded['expires_in'] ?? 3600)) - 120);
        set_transient(self::TOKEN_TRANSIENT, $decoded['access_token'], $ttl);
        return $decoded['access_token'];
    }

    private static function options(): array {
        $defaults = [
            'firebase_project_id' => 'wordnerd-artbeat',
            'service_account_json' => '',
            'facebook_page_id' => '',
            'facebook_page_access_token' => '',
        ];
        $options = get_option(self::OPTION_KEY, []);
        return array_merge($defaults, is_array($options) ? $options : []);
    }

    private static function sanitize_service_account_input($input): string {
        $raw = is_string($input) ? trim($input) : '';
        $unslashed = trim(wp_unslash($raw));

        foreach ([$raw, $unslashed] as $candidate) {
            $candidate = trim(preg_replace('/^\xEF\xBB\xBF/', '', $candidate));
            if ($candidate === '') {
                continue;
            }
            if (self::decode_service_account($candidate) !== null) {
                return $candidate;
            }
        }

        return preg_replace('/^\xEF\xBB\xBF/', '', $unslashed);
    }

    private static function project_id(): string {
        $project = self::options()['firebase_project_id'];
        if (!$project) {
            throw new RuntimeException('Firebase project ID is not configured.');
        }
        return $project;
    }

    private static function service_account(): array {
        $raw = self::options()['service_account_json'];
        $account = self::decode_service_account($raw);
        if (!is_array($account)) {
            throw new RuntimeException(self::json_error_message($raw));
        }
        foreach (['client_email', 'private_key', 'token_uri'] as $key) {
            if (empty($account[$key])) {
                throw new RuntimeException('Service account JSON is missing ' . $key . '.');
            }
        }
        return $account;
    }

    private static function service_account_diagnostics(string $raw): array {
        $raw = trim($raw);
        $summary = self::credential_storage_summary($raw);
        if ($raw === '') {
            return [
                'ok' => false,
                'message' => 'Firebase service account JSON has not been saved yet.',
            ];
        }

        $account = self::decode_service_account($raw);
        if (!is_array($account)) {
            return [
                'ok' => false,
                'message' => self::json_error_message($raw) . $summary,
            ];
        }

        $missing = [];
        foreach (['client_email', 'private_key', 'token_uri'] as $key) {
            if (empty($account[$key])) {
                $missing[] = $key;
            }
        }

        if ($missing) {
            return [
                'ok' => false,
                'message' => 'Service account JSON parsed, but is missing: ' . implode(', ', $missing) . '.' . $summary,
            ];
        }

        if (!function_exists('openssl_pkey_get_private')) {
            return [
                'ok' => false,
                'message' => 'Service account JSON parsed, but PHP OpenSSL is not available on this WordPress server.',
            ];
        }

        $key_resource = self::load_private_key($account['private_key']);
        if ($key_resource === false) {
            return [
                'ok' => false,
                'message' => 'Service account JSON parsed, but WordPress could not load the private_key. Re-paste the base64 service-account value, not the raw JSON.' . $summary . self::private_key_summary($account['private_key']) . self::openssl_error_summary(),
            ];
        }

        return [
            'ok' => true,
            'message' => 'Service account JSON parses correctly and the private key loads for ' . $account['client_email'] . '.' . $summary,
        ];
    }

    private static function credential_storage_summary(string $raw): string {
        $trimmed = trim($raw);
        if ($trimmed === '') {
            return '';
        }

        $compact = preg_replace('/\s+/', '', $trimmed);
        $decoded = base64_decode($compact, true);
        $format = is_string($decoded) && substr(trim($decoded), 0, 1) === '{'
            ? 'base64 JSON'
            : (substr($trimmed, 0, 1) === '{' ? 'raw JSON' : 'unknown text');
        $fingerprint = substr(hash('sha256', $trimmed), 0, 12);

        return ' Stored credential format: ' . $format . '; length: ' . strlen($trimmed) . '; fingerprint: ' . $fingerprint . '.';
    }

    private static function decode_service_account(string $raw): ?array {
        $raw = trim(preg_replace('/^\xEF\xBB\xBF/', '', $raw));
        if ($raw === '') {
            return null;
        }

        $decoded = json_decode($raw, true);
        if (is_array($decoded)) {
            return $decoded;
        }

        $unslashed = stripslashes($raw);
        if ($unslashed !== $raw) {
            $decoded = json_decode($unslashed, true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }

        $maybe_base64 = base64_decode(preg_replace('/\s+/', '', $raw), true);
        if (is_string($maybe_base64) && $maybe_base64 !== '') {
            $decoded = json_decode($maybe_base64, true);
            if (is_array($decoded)) {
                return $decoded;
            }
        }

        return null;
    }

    private static function json_error_message(string $raw): string {
        $trimmed = trim($raw);
        if ($trimmed === '') {
            return 'Service account JSON is empty.';
        }

        $prefix = substr($trimmed, 0, 1);
        $suffix = substr($trimmed, -1);
        $hint = ($prefix !== '{' || $suffix !== '}')
            ? ' It should start with { and end with }.'
            : '';

        return 'Service account JSON is invalid: ' . json_last_error_msg() . '.' . $hint;
    }

    private static function load_private_key(string $private_key) {
        foreach (self::private_key_candidates($private_key) as $candidate) {
            $key = openssl_pkey_get_private($candidate);
            if ($key !== false) {
                return $key;
            }
        }
        return false;
    }

    private static function private_key_candidates(string $private_key): array {
        $candidates = [];
        $decoded = html_entity_decode($private_key, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
        foreach ([$private_key, $decoded] as $candidate) {
            $candidates[] = trim($candidate);
            $candidates[] = self::normalize_private_key($candidate);
            $reconstructed = self::reconstruct_private_key($candidate);
            if ($reconstructed !== '') {
                $candidates[] = $reconstructed;
            }
            $slash_stripped = self::repair_slash_stripped_private_key($candidate);
            if ($slash_stripped !== '') {
                $candidates[] = $slash_stripped;
            }
        }

        $escaped_json = json_decode('"' . addcslashes($private_key, "\\\"\n\r\t") . '"');
        if (is_string($escaped_json)) {
            $candidates[] = self::normalize_private_key($escaped_json);
            $reconstructed = self::reconstruct_private_key($escaped_json);
            if ($reconstructed !== '') {
                $candidates[] = $reconstructed;
            }
        }

        return array_values(array_unique(array_filter($candidates)));
    }

    private static function normalize_private_key(string $private_key): string {
        $private_key = trim($private_key);
        $previous = null;
        while ($previous !== $private_key) {
            $previous = $private_key;
            $private_key = str_replace(['\\r\\n', '\\n', '\\r'], "\n", $private_key);
        }
        if (strpos($private_key, '-----BEGIN PRIVATE KEY-----') === false) {
            return $private_key;
        }
        if (substr($private_key, -1) !== "\n") {
            $private_key .= "\n";
        }
        return $private_key;
    }

    private static function reconstruct_private_key(string $private_key): string {
        $normalized = self::normalize_private_key($private_key);
        $begin = '-----BEGIN PRIVATE KEY-----';
        $end = '-----END PRIVATE KEY-----';
        $start = strpos($normalized, $begin);
        $finish = strpos($normalized, $end);
        if ($start === false || $finish === false || $finish <= $start) {
            return '';
        }

        $body_start = $start + strlen($begin);
        $body = substr($normalized, $body_start, $finish - $body_start);
        $body = preg_replace('/[^A-Za-z0-9+\/=]/', '', $body);
        if (!$body) {
            return '';
        }

        return $begin . "\n" . chunk_split($body, 64, "\n") . $end . "\n";
    }

    private static function repair_slash_stripped_private_key(string $private_key): string {
        $normalized = self::normalize_private_key($private_key);
        $begin = '-----BEGIN PRIVATE KEY-----';
        $end = '-----END PRIVATE KEY-----';
        $start = strpos($normalized, $begin);
        $finish = strpos($normalized, $end);
        if ($start === false || $finish === false || $finish <= $start) {
            return '';
        }

        $body_start = $start + strlen($begin);
        $body = substr($normalized, $body_start, $finish - $body_start);
        $body = preg_replace('/\s+/', '', $body);
        $body = trim($body, 'n');
        if ($body === '') {
            return '';
        }

        $repaired = '';
        $line_count = 0;
        $length = strlen($body);
        for ($index = 0; $index < $length; $index++) {
            $char = $body[$index];
            if ($line_count === 64 && $char === 'n') {
                $line_count = 0;
                continue;
            }

            $repaired .= $char;
            $line_count++;
        }

        $repaired = preg_replace('/[^A-Za-z0-9+\/=]/', '', $repaired);
        if ($repaired === '' || strlen($repaired) % 4 !== 0) {
            return '';
        }

        return $begin . "\n" . chunk_split($repaired, 64, "\n") . $end . "\n";
    }

    private static function private_key_summary(string $private_key): string {
        $normalized = self::normalize_private_key($private_key);
        $begin = '-----BEGIN PRIVATE KEY-----';
        $end = '-----END PRIVATE KEY-----';
        $has_begin = strpos($normalized, $begin) !== false;
        $has_end = strpos($normalized, $end) !== false;
        $body = '';

        if ($has_begin && $has_end) {
            $body_start = strpos($normalized, $begin) + strlen($begin);
            $body_end = strpos($normalized, $end);
            $body = substr($normalized, $body_start, $body_end - $body_start);
        }

        $body_compact = preg_replace('/\s+/', '', $body);
        $invalid_count = strlen(preg_replace('/[A-Za-z0-9+\/=]/', '', $body_compact));
        $fingerprint = substr(hash('sha256', $normalized), 0, 12);

        return ' Private key summary: begin=' . ($has_begin ? 'yes' : 'no')
            . '; end=' . ($has_end ? 'yes' : 'no')
            . '; body_length=' . strlen($body_compact)
            . '; invalid_body_chars=' . $invalid_count
            . '; fingerprint=' . $fingerprint . '.';
    }

    private static function openssl_error_summary(): string {
        $errors = [];
        while (($error = openssl_error_string()) !== false) {
            $errors[] = $error;
        }
        if (!$errors) {
            return '';
        }
        return ' OpenSSL: ' . implode(' | ', array_unique($errors));
    }

    private static function reviewer_label(): string {
        $user = wp_get_current_user();
        return $user && $user->exists()
            ? ($user->user_email ?: $user->user_login)
            : 'wordpress-admin';
    }

    private static function capture_stats(array $captures): array {
        $stats = [
            'approved' => 0,
            'pending' => 0,
            'rejected' => 0,
            'public' => 0,
            'private' => 0,
            'flagged' => 0,
            'reports' => 0,
            'likes' => 0,
            'shares' => 0,
            'promoted' => 0,
            'last_7_days' => 0,
        ];
        $cutoff = time() - 7 * 86400;

        foreach ($captures as $row) {
            $fields = $row['fields'];
            $status = self::field($fields, 'status') ?: 'unknown';
            if (isset($stats[$status])) {
                $stats[$status]++;
            }
            if (self::bool_field($fields, 'isPublic')) {
                $stats['public']++;
            } else {
                $stats['private']++;
            }
            if (self::bool_field($fields, 'isFlagged')) {
                $stats['flagged']++;
            }
            if (self::field($fields, 'adminPromotionStatus') === 'promoted') {
                $stats['promoted']++;
            }
            $stats['reports'] += self::int_field($fields, 'reportCount');
            $engagement = self::map_field($fields, 'engagementStats');
            $stats['likes'] += self::map_int($engagement, 'likeCount');
            $stats['shares'] += self::map_int($engagement, 'shareCount');

            $created = strtotime(self::timestamp_field($fields, 'createdAt'));
            if ($created && $created >= $cutoff) {
                $stats['last_7_days']++;
            }
        }

        return $stats;
    }

    private static function status_counts(array $rows, string $field): array {
        $counts = [];
        foreach ($rows as $row) {
            $status = self::field($row['fields'], $field) ?: 'unknown';
            $counts[$status] = ($counts[$status] ?? 0) + 1;
        }
        ksort($counts);
        return $counts;
    }

    private static function active_user_count(array $users, int $days): int {
        $cutoff = time() - $days * 86400;
        $count = 0;
        foreach ($users as $row) {
            $last_active = strtotime(self::timestamp_field($row['fields'], 'lastActive') ?: self::timestamp_field($row['fields'], 'updatedAt') ?: self::timestamp_field($row['fields'], 'createdAt'));
            if ($last_active && $last_active >= $cutoff) {
                $count++;
            }
        }
        return $count;
    }

    private static function top_values(array $rows, string $field, int $limit): array {
        $counts = [];
        foreach ($rows as $row) {
            $value = self::field($row['fields'], $field);
            if ($value === '') {
                continue;
            }
            $counts[$value] = ($counts[$value] ?? 0) + 1;
        }
        arsort($counts);
        return array_slice($counts, 0, $limit, true);
    }

    private static function top_capture_locations(array $rows, int $limit): array {
        $counts = [];
        foreach ($rows as $row) {
            $value = self::capture_location_label($row['fields']);
            if ($value === 'Unknown location') {
                continue;
            }
            $counts[$value] = ($counts[$value] ?? 0) + 1;
        }
        arsort($counts);
        return array_slice($counts, 0, $limit, true);
    }

    private static function filter_captures(array $captures, string $filter): array {
        return array_values(array_filter($captures, function ($row) use ($filter) {
            $fields = $row['fields'];
            if ($filter === 'public') {
                return self::bool_field($fields, 'isPublic');
            }
            if ($filter === 'flagged') {
                return self::bool_field($fields, 'isFlagged') || self::int_field($fields, 'reportCount') > 0;
            }
            if ($filter === 'promoted') {
                return self::field($fields, 'adminPromotionStatus') === 'promoted';
            }
            if ($filter === 'social') {
                return self::bool_field($fields, 'isPublic')
                    && self::field($fields, 'status') !== 'rejected'
                    && self::field($fields, 'adminPromotionStatus') !== 'promoted'
                    && !self::bool_field($fields, 'isFlagged')
                    && self::field($fields, 'imageUrl') !== '';
            }
            return true;
        }));
    }

    private static function social_caption(array $fields): string {
        $title = self::first_nonempty([self::field($fields, 'title'), 'A local art discovery']);
        $artist = self::field($fields, 'artistName');
        $location = self::capture_location_label($fields);
        if ($location === 'Unknown location') {
            $location = '';
        }
        $user = self::first_nonempty([self::field($fields, 'userName'), self::field($fields, 'userHandle')]);
        $description = self::field($fields, 'description');
        $tags = self::array_field($fields, 'tags');
        $hashtag_tail = $tags
            ? ' #' . implode(' #', array_map(function ($tag) {
                return self::hashtag_text((string) $tag);
            }, array_slice($tags, 0, 4)))
            : '';

        $caption = $title;
        if ($artist !== '') {
            $caption .= ' by ' . $artist;
        }
        if ($location !== '') {
            $caption .= ' spotted in ' . $location;
        }
        $caption .= ".";
        if ($description !== '') {
            $caption .= "\n\nAbout this capture: " . $description;
        }
        $caption .= "\n\nCaptured with Local ARTbeat";
        if ($user !== '') {
            $caption .= ' by ' . $user;
        }
        $caption .= ".\n\nThis is the Local ARTbeat experience: capture public art, map the discovery, share it with the community, and help more people find the art hiding in plain sight.";
        $caption .= "\n\nDiscover more local art near you in the Local ARTbeat app. #LocalARTbeat #PublicArt #LocalArt" . $hashtag_tail;
        return $caption;
    }

    private static function publish_capture_to_facebook_page(array $fields, string $notes): string {
        $options = self::options();
        $page_id = trim($options['facebook_page_id']);
        $token = trim($options['facebook_page_access_token']);
        if ($page_id === '' || $token === '') {
            throw new RuntimeException('Facebook Page ID and Page access token are not configured in Local ARTbeat settings.');
        }

        $image = self::first_nonempty([self::field($fields, 'imageUrl'), self::field($fields, 'thumbnailUrl')]);
        if ($image === '') {
            throw new RuntimeException('This capture does not have an image URL to publish.');
        }

        $caption = self::social_caption($fields);
        if ($notes !== '') {
            $caption .= "\n\n" . $notes;
        }

        $url = 'https://graph.facebook.com/v25.0/' . rawurlencode($page_id) . '/photos';
        $response = wp_remote_post($url, [
            'timeout' => 30,
            'body' => [
                'url' => $image,
                'message' => $caption,
                'access_token' => $token,
            ],
        ]);

        if (is_wp_error($response)) {
            throw new RuntimeException($response->get_error_message());
        }

        $code = (int) wp_remote_retrieve_response_code($response);
        $decoded = json_decode(wp_remote_retrieve_body($response), true);
        if ($code < 200 || $code >= 300) {
            $message = is_array($decoded) && isset($decoded['error']['message'])
                ? $decoded['error']['message']
                : 'Facebook photo publish failed.';
            throw new RuntimeException($message);
        }

        $post_id = $decoded['post_id'] ?? $decoded['id'] ?? '';
        if (!is_string($post_id) || $post_id === '') {
            throw new RuntimeException('Facebook did not return a post ID.');
        }

        return $post_id;
    }

    private static function facebook_share_url(array $fields, string $caption): string {
        $image = self::first_nonempty([self::field($fields, 'imageUrl'), self::field($fields, 'thumbnailUrl')]);
        if ($image === '') {
            return '';
        }

        return 'https://www.facebook.com/sharer/sharer.php?' . http_build_query([
            'u' => $image,
            'quote' => $caption,
        ], '', '&', PHP_QUERY_RFC3986);
    }

    private static function capture_location_label(array $fields): string {
        $label = self::first_nonempty([
            self::field($fields, 'locationName'),
            self::field($fields, 'address'),
        ]);
        if ($label !== '') {
            return $label;
        }

        $point = self::geo_point_field($fields, 'location');
        if ($point !== null) {
            return number_format($point['latitude'], 5) . ', ' . number_format($point['longitude'], 5);
        }

        $lat = self::numeric_field($fields, 'latitude');
        $lng = self::numeric_field($fields, 'longitude');
        if ($lat !== null && $lng !== null) {
            return number_format($lat, 5) . ', ' . number_format($lng, 5);
        }

        return 'Unknown location';
    }

    private static function capture_maps_url(array $fields): string {
        $point = self::geo_point_field($fields, 'location');
        if ($point === null) {
            $lat = self::numeric_field($fields, 'latitude');
            $lng = self::numeric_field($fields, 'longitude');
            if ($lat !== null && $lng !== null) {
                $point = ['latitude' => $lat, 'longitude' => $lng];
            }
        }
        if ($point === null) {
            return '';
        }
        return 'https://www.google.com/maps/search/?api=1&query=' . rawurlencode($point['latitude'] . ',' . $point['longitude']);
    }

    private static function hashtag_text(string $text): string {
        return preg_replace('/[^A-Za-z0-9]/', '', ucwords($text));
    }

    private static function first_nonempty(array $values): string {
        foreach ($values as $value) {
            $value = is_string($value) ? trim($value) : '';
            if ($value !== '') {
                return $value;
            }
        }
        return '';
    }

    private static function field(array $fields, string $key): string {
        $value = $fields[$key] ?? null;
        if (!is_array($value)) {
            return '';
        }
        if (array_key_exists('stringValue', $value)) {
            return (string) $value['stringValue'];
        }
        if (array_key_exists('integerValue', $value)) {
            return (string) $value['integerValue'];
        }
        if (array_key_exists('doubleValue', $value)) {
            return (string) $value['doubleValue'];
        }
        if (array_key_exists('booleanValue', $value)) {
            return $value['booleanValue'] ? 'true' : 'false';
        }
        if (array_key_exists('timestampValue', $value)) {
            return (string) $value['timestampValue'];
        }
        return '';
    }

    private static function int_field(array $fields, string $key): int {
        return (int) self::field($fields, $key);
    }

    private static function bool_field(array $fields, string $key): bool {
        return (($fields[$key]['booleanValue'] ?? false) === true);
    }

    private static function numeric_field(array $fields, string $key): ?float {
        $value = $fields[$key] ?? null;
        if (!is_array($value)) {
            return null;
        }
        if (array_key_exists('doubleValue', $value)) {
            return (float) $value['doubleValue'];
        }
        if (array_key_exists('integerValue', $value)) {
            return (float) $value['integerValue'];
        }
        if (array_key_exists('stringValue', $value) && is_numeric($value['stringValue'])) {
            return (float) $value['stringValue'];
        }
        return null;
    }

    private static function geo_point_field(array $fields, string $key): ?array {
        $value = $fields[$key]['geoPointValue'] ?? null;
        if (!is_array($value)) {
            return null;
        }

        $lat = $value['latitude'] ?? null;
        $lng = $value['longitude'] ?? null;
        if (!is_numeric($lat) || !is_numeric($lng)) {
            return null;
        }

        $lat = (float) $lat;
        $lng = (float) $lng;
        if ($lat < -90 || $lat > 90 || $lng < -180 || $lng > 180) {
            return null;
        }

        return ['latitude' => $lat, 'longitude' => $lng];
    }

    private static function timestamp_field(array $fields, string $key): string {
        return self::field($fields, $key);
    }

    private static function format_datetime(string $timestamp): string {
        $time = strtotime($timestamp);
        if (!$time) {
            return '';
        }
        return wp_date('M j, Y g:i a', $time);
    }

    private static function array_field(array $fields, string $key): array {
        $values = $fields[$key]['arrayValue']['values'] ?? [];
        $out = [];
        foreach ($values as $value) {
            if (isset($value['stringValue'])) {
                $out[] = (string) $value['stringValue'];
            }
        }
        return $out;
    }

    private static function map_field(array $fields, string $key): array {
        return $fields[$key]['mapValue']['fields'] ?? [];
    }

    private static function map_value(array $map, string $key): string {
        return self::field($map, $key);
    }

    private static function map_int(array $map, string $key): int {
        return (int) self::field($map, $key);
    }

    private static function base64url(string $data): string {
        return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
    }
}

Local_ARTbeat_Moderator_Plugin::boot();
