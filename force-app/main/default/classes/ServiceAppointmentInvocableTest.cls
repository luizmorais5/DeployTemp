/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 10-07-2023
 * @last modified by  : Remario Richards
 **/
@isTest
public with sharing class ServiceAppointmentInvocableTest {
  /**
   * @description test within business hours
   * @author Remario Richards | 10-05-2023
   **/
  @isTest
  public static void shouldIsWithinBusinessHours() {
    List<ServiceAppointmentInvocable.Input> inputs = new List<ServiceAppointmentInvocable.Input>();
    ServiceAppointmentInvocable.Input input = new ServiceAppointmentInvocable.Input();
    input.caseId = '';
    inputs.add(input);

    Assert.areNotEqual(
      null,
      ServiceAppointmentInvocable.isWithinBusinessHours(inputs),
      'BusinessHours should not be null'
    );
  }
}