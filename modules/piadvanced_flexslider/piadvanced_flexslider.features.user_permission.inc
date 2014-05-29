<?php
/**
 * @file
 * piadvanced_flexslider.features.user_permission.inc
 */

/**
 * Implements hook_user_default_permissions().
 */
function piadvanced_flexslider_user_default_permissions() {
  $permissions = array();

  // Exported permission: 'access draggableviews'.
  $permissions['access draggableviews'] = array(
    'name' => 'access draggableviews',
    'roles' => array(
      'site editor' => 'site editor',
    ),
    'module' => 'draggableviews',
  );

  // Exported permission: 'administer flexslider'.
  $permissions['administer flexslider'] = array(
    'name' => 'administer flexslider',
    'roles' => array(),
    'module' => 'flexslider',
  );

  return $permissions;
}
