<?php
/**
 * @file
 * piadvanced_flexslider.features.inc
 */

/**
 * Implements hook_views_api().
 */
function piadvanced_flexslider_views_api($module = NULL, $api = NULL) {
  return array("api" => "3.0");
}

/**
 * Implements hook_node_info().
 */
function piadvanced_flexslider_node_info() {
  $items = array(
    'slideshow_image' => array(
      'name' => t('Slideshow Image'),
      'base' => 'node_content',
      'description' => t('Add a slideshow image that will rotate in the slideshow.'),
      'has_title' => '1',
      'title_label' => t('Name of Slide'),
      'help' => '',
    ),
  );
  return $items;
}
