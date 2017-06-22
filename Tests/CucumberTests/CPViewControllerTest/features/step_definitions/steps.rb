# Given the application is lauched
Given /^the application is launched$/ do
  launched = app.gui.command "launched"

  if !launched
    raise "The application was not launched"
  end
end

# Given I wait for n seconds
Given /^I wait for (\d+) seconds?$/ do |n|
  sleep(eval("#{n.to_i}"))
end

# When I close the popover
When /^I close the popover$/ do
  step "I hit the key escape"
end


# When I hit the key c
When /^I hit the key (.*)$/ do |key|
  step "I hit the mask none and the key #{key}"
end


# When I hit the mask shif and the key c
When /^I hit the mask (.*) and the key (.*)$/ do |mask, key|
  simulate_keyboard_event(key, mask)
end


# When the keys cucapp
When /^I hit the keys (.*)$/ do |keys|
  step "I hit the mask none and keys #{keys}"
end


# When I hit the mask shif and the keys cucapp
When /^I hit the mask (.*) and keys (.*)$/ do |mask, keys|
  simulate_keyboard_event(keys, mask)
end


# When I select all
When /^I select all$/ do
  app.gui.simulate_keyboard_event    "a", [$CPCommandKeyMask]
end


# When I save the document
When /^I save the document$/ do
  app.gui.simulate_keyboard_event    "s", [$CPCommandKeyMask]
end


# When I (click|right click|double click) on the field with the value cucapp
When /^I (click|right click|double click) on the (\w*\-*\w*) with the value (.*)$/ do |click_type, element, value|
  step "I #{click_type} on the #{element} with the property object-value set to #{value}"
end


# When I click on the field with the property cucapp-identifier set to cucapp-identifier-button-add
When /^I (click|right click|double click) on the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*)$/ do |click_type, element, property, property_value|
  step "I #{click_type} with the key mask none on the #{element} with the property #{property} set to #{property_value}"
end


# When I click with the mask shift on the field with the property cucapp-identifier set to cucapp-identifier-button-add
When /^I (click|right click|double click) with the key mask (.*) on the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*)$/ do |click_type, mask, element,  property, property_value|

  type = $mouse_left_click

  if click_type == "right click"
    type = $mouse_right_click
  end

  if click_type == "double click"
    type = $mouse_double_click
  end

  simulate_click(type, element, property, property_value, mask)
end


# When I do a drag and drop from the field with the value cucapp to the field with the value cappuccino
When /^I do a drag and drop from the (\w*\-*\w*) with the value (.*) to the (\w*\-*\w*) with the value (.*)$/ do |element, value, second_element, second_value|
  step "I do a drag and drop from the #{element} with the property object-value set to #{value} to the #{second_element} with the property object-value set to #{second_value}"
end


# When I do a drag and drop from the field with the property title set to cucapp to the field with the property title set to cappuccino
When /^I do a drag and drop from the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*) to the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*)$/ do |element, property, property_value, second_element, second_property, second_property_value|
  step "I do a drag and drop with the key mask none from the #{element} with the property #{property} set to #{property_value} to the #{second_element} with the property #{second_property} set to #{second_property_value}"
end


# When I do a drag and drop with the key mask shift from the field with the property title set to cucapp to the field with the property title set to cappuccino
When /^I do a drag and drop with the key mask (.*) from the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*) to the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*)$/ do |mask, element, property, property_value, second_element, second_property, second_property_value|
  simulate_drag_and_drop(element, property, property_value, second_element, second_property, second_property_value, mask)
end


# When I vertically|horizontally scroll on the field with the value cappuccino
When /^I (vertically|horizontally) scroll on the (\w*\-*\w*) with the value (.*)$/ do |direction, element, value|
  step "When I #{direction} scroll 10 times on the #{element} with the value #{value}"
end


# When I vertically|horizontally scroll 10 times on the field with the value cappuccino
When /^I (vertically|horizontally) scroll ([0-9]*) times on the (\w*\-*\w*) with the value (.*)$/ do |direction, times, element, value|
  step "I #{direction} scroll #{times} times on the #{element} with the property object-value set to #{value}"
end


# When I vertically|horizontally scroll 10 times on the field with the property title set to cappuccino
When /^I (vertically|horizontally) scroll ([0-9]*) times on the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*)$/ do |direction, times, element, property, property_value|
  step "I #{direction} scroll #{times} times with the key mask none on the #{element} with the property #{property} set to #{property_value}"
end


# When I vertically|horizontally scroll 10 times on the field with the property title set to cappuccino
When /^I (vertically|horizontally) scroll ([0-9]*) times with the key mask (.*) on the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*)$/ do |direction, times, mask, element, property, property_value|

  vertically = false
  horizontally = false

  if direction == "vertically"
    vertically = true
  end

  if direction == "horizontally"
    horizontally = true
  end

  simulate_scroll(element, property, property_value, times, mask, horizontally, vertically)
end


# When I select the item name of the pop-up-button with the property cucapp-identifier set to cucappIdentifierPopUpButton
When /^I select the item (.*) of the pop-up-button with the property (\w*\-*\w*) set to (.*)$/ do |item_name, property, property_value|
  select_pop_up_button_item(item_name, property, property_value)
end


# Then the field with the property title set to name should be focused
Then /^the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*) should be focused$/ do |element, property, property_value|
  app.gui.is_control_focused(create_xpath(element, property, property_value))
end


# Then the field should not have a value
Then /^the (\w*\-*\w*) should not have a value$/ do |element|
  step "the #{element} with the property object-value set to #{value} should have the value #{value}"
end


# Then the field with the property cucapp-identifier set to cucapp-identifier-textfield-description should not have a value
Then /^the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*) should not have a value$/ do |element, property, property_value|
  check_value_control(element, property, property_value, nil)
end


# Then the field should have the value cucapp
Then /^the (\w*\-*\w*) should have the value (.*)$/ do |element, value|
  step "the #{element} with the property object-value set to #{value} should have the value #{value}"
end


# Then the field with the property cucapp-identifier set to cucapp-identifier-textfield-description should have the value cucapp
Then /^the (\w*\-*\w*) with the property (\w*\-*\w*) set to (.*) should have the value (.*)$/ do |element, property, property_value, value|
  check_value_control(element, property, property_value, value)
end
