<?php
// include form function for feature_set
!function_exists('feature_set_admin_form') ? module_load_include('inc', 'feature_set', 'feature_set.admin') : FALSE;

/**
 * Implements form_alter for the configuration form
 */
function piadvanced_form_install_configure_form_alter(&$form, $form_state) {

  // Pre-populate the site name with the server name.
  $form['site_information']['site_name']['#default_value'] = $_SERVER['SERVER_NAME'];

  // Adjust date options so that date/date API is happy on install
  module_load_include('inc', 'system', 'system.admin');
  $regional_form = system_regional_settings();
  $form['server_settings']['date_first_day'] = $regional_form['locale']['date_first_day'];
  $settings = system_date_time_settings();
  $form['server_settings']['formats'] = $settings['formats'];
  $form = system_settings_form($form);

  // Add additional user prompting to indicate admin account usage
  $form['admin_account']['leadin'] = array(
    '#markup' => t('This account should be used and strictly for administrative purposes only.'),
    '#weight' => -100,
  );
  $form['admin_account']['account']['mail']['#description'] = t('');
  // Set the defaults used every time
  $form['admin_account']['account']['mail']['#value'] = "deven@precisionintermedia.com";
  $form['admin_account']['account']['name']['#value'] = 'piadmin';
  $form['update_notifications']['update_status_module']['#default_value'] = array(0,0);

  // date api and image resize filter throw a few warnings that we don't want;
  //drupal_get_messages('warning', TRUE);
  //drupal_get_messages('status', TRUE);
  //drupal_get_messages('error', TRUE);
  

  // make a few choices to avoid extraneous choices and warnings to the end-user
  $form['server_settings']['site_default_country']['#type'] = 'value';
  $form['server_settings']['site_default_country']['#value'] = 'US';
  unset($form['server_settings']['formats']['#theme']);
  $form['server_settings']['formats']['format']['date_format_long']['#type'] = 'value';
  $form['server_settings']['formats']['format']['date_format_long']['#value'] = 'l, F j, Y - g:ia';
  $form['server_settings']['formats']['format']['date_format_medium']['#type']  = 'value';
  $form['server_settings']['formats']['format']['date_format_medium']['#value'] = 'D, m/d/Y - g:ia';
  $form['server_settings']['formats']['format']['date_format_short']['#type']  = 'value';
  $form['server_settings']['formats']['format']['date_format_short']['#value'] = 'm/d/Y - g:ia';
  $form['server_settings']['date_first_day']['#type'] = 'value';
  $form['server_settings']['date_first_day']['#value'] = '0';
}

/**
 * Implements form_alter for the feature set form
 */
function piadvanced_form_feature_set_admin_form_alter(&$form, $form_state) {
  // Default disable all feature-sets on install
  if (isset($form_state['build_info']['args'][0])) {
    $install_state = $form_state['build_info']['args'][0];
  }
  if (isset($install_state['installation_finished']) && $install_state['installation_finished'] === FALSE) {
    foreach(element_children($form) as $element) {
      if (strpos($element, 'featureset-') === 0) {
        $form[$element]['#default_value'] = FALSE;
      }
    }
  }
}

/**
 * Implements form_alter for user_register (only during install)
 */
function piadvanced_form_user_register_form_alter(&$form, $form_state) {
  // we only want to run during install time
  $profile = variable_get('install_profile', '');
  if (empty($profile)) {
    $form['leadin']['#markup'] = t('Create a general user account. This will be your day-to-day account and will be used for all tasks besides site upgrades.');
    $form['leadin']['#weight'] = -300;

    /* give user all roles
    $rids = array_keys($form['account']['roles']['#options']);
    // make sure the authenticated role in included
    $form['account']['roles']['#default_value'] = $rids;
    */
    
    $hide = array(
      'account' => array('status', 'notify'),
    );

    foreach ($hide as $sub => $fields) {
      foreach($fields as $field) {
        $form[$sub][$field]['#access'] = FALSE;
      }
    }
  }
}

/**
 * Implements hook_install_tasks().
 */
function piadvanced_install_tasks() {
  module_load_include('module', 'feature_set', 'feature_set.admin.inc');

  $tasks = feature_set_install_tasks();

/* Needs work, should be a panel node with layout of panel
  $tasks['piadvanced_core_homepage_layout_select_form'] = array(
    'display_name' => st('Homepage Layout'),
    'type' => 'form',
  );
  */

  /*
  $tasks['user_register_form'] = array(
    'display_name' => st('Add General User'),
    'type' => 'form'
  );
  */

  $tasks['piadvanced_install_cleanup_batch'] = array(
    'display_name' => st('Cleanup'),
    'type' => 'batch'
  );

  return $tasks;
}

/**
 * Defines batch set for necessary cleanup
 * Batch processing is necessary because we need multiple requests to ensure
 * caches are properly rebuilt/available.
 */
function piadvanced_install_cleanup_batch($install_state) {
  return array(
    'operations' => array(
      array('piadvanced_install_cleanup_stage1', array()),
      array('piadvanced_install_cleanup_stage2', array()),
    ),
    'title' => t('Performing cleanup'),
  );
}

/**
 *
 */
function piadvanced_install_cleanup_stage1(&$context) {
  // make sure default theme is enabled
  $theme = variable_get('theme_default', 'watt');
  theme_enable(array($theme));

  // remove default 'bookmark' flag
  /*
  $flags = flag_get_flags();
  foreach($flags as $flag) {
    if ($flag->name == 'bookmarks') {
      $flag->delete();
    }
  }
  */

  // media gallery puts a link in the main-menu :/
  $query = db_select('menu_links', 'ml');
  $query->condition('menu_name', 'main-menu');
  $query->condition('link_title', 'Taxonomy term');
  $query->condition('weight', 10);
  $query->fields('ml', array('mlid'));
  if ($item = $query->execute()->fetchAssoc()) {
    menu_link_delete($item['mlid']);
  }

  drupal_flush_all_caches();

}

/**
 *
 */
function piadvanced_install_cleanup_stage2(&$context) {

  // set some default cache settinsg
  $cache_vars = array(
    'block_cache' => 1,
    'cache' => 1,
    'cache_lifetime' => 60,
    'page_cache_maximum_age' => 3600,
    'preprocess_css' => 1,
    'preprocess_js' => 1,
  );

  foreach ($cache_vars as $var => $value) {
    variable_set($var, $value);
  }

  // disable bartik
  // theme_disable(array('bartik'));

  $features_revert = array(
    //'piadvanced_administrative_unit_announcements', // required for og permissions
    //'piadvanced_administrative_unit_galleries', // required for og permissions
  );

  foreach ($features_revert as $module) {
    if (($feature = feature_load($module, TRUE)) && module_exists($module)) {
      $components = array();

      // Gather all the feature components.
      foreach (array_keys($feature->info['features']) as $component) {
        if (features_hook($component, 'features_revert')) {
          $components[] = $component;
        }
      }

      // Revert each component.
      foreach ($components as $component) {
        features_revert(array($module => array($component)));
      }
    }
  }
}
