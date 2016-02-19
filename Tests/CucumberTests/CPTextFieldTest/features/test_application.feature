Feature: Test the launching of the application
This test is used to make sure that we can launch the application

  Scenario: Check if the application is launched
    Given the application is launched
    When I click on the field with the property cucapp-identifier set to text-field-cucapp-identifier
    When I hit the keys CucappAndCappuccino
    Then the field should have the value CucappAndCappuccino
