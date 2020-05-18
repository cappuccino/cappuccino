def check_value_control(element, property, property_value, value)
  xpath = create_xpath(element, property, property_value)

  app.gui.wait_for        xpath
  app.gui.value_is_equal  xpath, value
end

def simulate_keyboard_event(keys, mask)
  app.gui.simulate_keyboard_events    cappuccino_key(keys), [cappuccino_key(mask)]
end

def simulate_click(type, element, property, property_value, mask)
  xpath = create_xpath(element, property, property_value)

  app.gui.wait_for              xpath

  if type == $mouse_double_click
    app.gui.simulate_double_click   xpath, [cappuccino_key(mask)]
  elsif type == $mouse_right_click
    app.gui.simulate_right_click    xpath, [cappuccino_key(mask)]
  else
    app.gui.simulate_left_click     xpath, [cappuccino_key(mask)]
  end
end

def simulate_drag_and_drop(element, property, property_value, second_element, second_property, second_property_value, mask)

  xpath1 = create_xpath(element, property, property_value)
  xpath2 = create_xpath(second_element, second_property, second_property_value)

  app.gui.simulate_dragged_click_view_to_view xpath1, xpath2, [cappuccino_key(mask)]
end

def simulate_scroll(element, property, property_value, times, mask, horizontal, vertical)
  xpath = create_xpath(element, property, property_value)
  delta_x = 0
  delta_y = 0

  if horizontal
    delta_x = 1
  end

  if vertical
    delta_y = 1
  end

  for i in 0..times.to_i
    app.gui.simulate_scroll_wheel xpath, delta_x, delta_y, [cappuccino_key(mask)]
  end
end

def select_pop_up_button_item(item_name, property, property_value)
  simulate_click($mouse_left_click, "pop-up-button", property, property_value, [])

  pop_up_button_xpath = create_xpath("pop-up-button", property, property_value)

  pop_up_button_item_xpath = create_xpath("image-view-text", "text", item_name)

  while !app.gui.wait_for_element(pop_up_button_item_xpath, 0.05) && app.gui.pop_up_button_can_scroll_up(pop_up_button_xpath)
    simulate_keyboard_event("up-arrow", [])
  end

  while !app.gui.wait_for_element(pop_up_button_item_xpath, 0.05) && app.gui.pop_up_button_can_scroll_down(pop_up_button_xpath)
    simulate_keyboard_event("down-arrow", [])
  end

  if not app.gui.wait_for(pop_up_button_item_xpath)
    raise "Menu item #{item_name} not found !"
  end

  simulate_click($mouse_left_click, "image-view-text", "text", item_name, [])
end

def cappuccino_key(key)
  if $key_mappings.has_key?(key)
    key = $key_mappings[key]
  end

  return key
end

def create_xpath(element, property, property_value)
  if !$cappuccino_control_mappings.has_key?(element)
    raise "Element #{element} not found in the hash cappuccino_control_mappings. You should complete the hash $cappuccino_control_mappings in env.rb"
  end

  if !$property_mappings.has_key?(property)
    raise "Property #{property} not found in the hash $property_mappings. You should complete the hash $property_mappings in env.rb"
  end

  return "//" + $cappuccino_control_mappings[element] + "["+ $property_mappings[property] +"='#{property_value}']"
end