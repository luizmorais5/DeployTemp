/**
 * @description       :
 * @author            : Remario Richards
 * @group             :
 * @last modified on  : 12-24-2023
 * @last modified by  : Remario Richards
 **/
public with sharing class ServiceAppointmentInvocable {
  @InvocableMethod(
    label='Within Business Hours'
    description='Checks if within business hours'
    callout=false
  )
  /**
   * @description check changes to the object is within business hours
   * @author Remario Richards | 09-05-2023
   * @return Output
   **/
  public static List<Output> isWithinBusinessHours(List<Input> inputs) {
    Datetime currentTime = Datetime.now();
    List<Output> outputs = new List<Output>();
    Assert.isFalse(inputs == null, 'Expected Inputs must not be null');
    for (Input inputRecord : inputs) {
      BusinessHours record = EntitlementSettingWrapper.searchBusinessHourRecordForBank(
        inputRecord.merchantBankName
      );
      Output output = new Output();
      if (record == null) {
        output.isWithin = false;
      } else {
        output.isWithin = BusinessHours.isWithin(record.Id, currentTime);
      }
      outputs.add(output);
    }
    return outputs;
  }
  public class Output {
    @InvocableVariable
    public Boolean isWithin;
  }
  public class Input {
    @InvocableVariable
    public String caseId;
    @InvocableVariable
    public String merchantBankName;
  }
}