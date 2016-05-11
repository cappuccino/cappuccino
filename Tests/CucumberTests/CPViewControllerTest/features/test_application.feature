Feature: Test the CPViewController asynchronous loading
This test is used to make sure that the isViewLoaded property is true when the loading has ended.

  Scenario: Check if the application is launched
    Given the application is launched
    When I click on the button with the property identifier set to load
    Given I wait for 1 second
    Then the field with the property identifier set to result should have the value isViewLoaded=true
