/*
    Copyright (c) 2022, Salesforce.org
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Salesforce.org nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/

/**
* @author Salesforce.org
* @date 2022
* @group Donation
* @description Controller class for Recurring Donations LWC.
*/
public with sharing class RD2_ETableController {
    
    private final String STATUS_CANCELED = 'Canceled';

    @TestVisible
    private UTIL_Permissions permissions {
        get {
            if(permissions == null) {
                permissions = UTIL_Permissions.getInstance();
            }
            return permissions;
        }
        set;
    }

    @TestVisible
    private static RD2_ETableController controller {
        get {
            if (controller == null) {
                controller = new RD2_ETableController();
            }
            return controller;
        }
        set {
            controller = value;
        }
    }

    @TestVisible
    private static RD2_ERecurringDonationsSelector selector {
        get {
            if(selector == null) {
                selector = new RD2_ERecurringDonationsSelector();
            }
            return selector;
        }
        set { 
            selector = value;
        }
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description Recurring Donations inner class.
    */
    public class TableView {
        @AuraEnabled public npe03__Recurring_Donation__c recurringDonation;
        @AuraEnabled public String frequency;
        @AuraEnabled public String status;
        @AuraEnabled public String paymentMethod;
        public TableView(npe03__Recurring_Donation__c recurringDonation, String frequency, String status, String paymentMethod) {
            this.recurringDonation = recurringDonation;
            this.frequency = frequency;
            this.status = status;
            this.paymentMethod = paymentMethod;
        }
    }

    /**
     * @description returns a list of processed recurring donations
     * @return List<TableView> List of processed recurring donation records
     */
    @AuraEnabled(cacheable=true)
    public static List<TableView> getData() {
        try {
            return controller.getTableViews();
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /** 
    * @author Salesforce.org
    * @date 2022
    * @description method to return Recurring Donation list.
    * @return List<RD2_ETableController.TableView> returns processed Recurring Donations.
    */
    private List<RD2_ETableController.TableView> getTableViews() {
        List<RD2_ETableController.TableView> recurringDonations = new List<RD2_ETableController.TableView>();
        if(RD2_EnablementService.isRecurringDonations2Enabled) {
            if(controller.hasAccessToRecurringDonation()) {
                for(npe03__Recurring_Donation__c recDonation : selector.getRecurringDonations()) {
                    recurringDonations.add( new RD2_ETableController.TableView( recDonation,
                                                                                controller.getFrequency(recDonation),
                                                                                controller.getStatus(recDonation),
                                                                                controller.getPaymentMethod(recDonation)));
    
                }
            } else {
                throw new UTIL_Permissions.InsufficientPermissionException(Label.commonInsufficientPermissions);
            }
        }

        return recurringDonations;
        
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation record to build the frequency string.
    * @param recurringDonation recurring donation record
    * @return String returns the frequency string.
    */
    private String getFrequency(npe03__Recurring_Donation__c recurringDonation) {

        String frequency = '';

        Map<String, String> mapDayOfMonth = new Map<String, String>();
        for(Schema.PicklistEntry ple : Schema.SObjectType.npe03__Recurring_Donation__c.fields.Day_of_Month__c.getPicklistValues()){
            mapDayOfMonth.put(ple.getValue(), ple.getLabel());
        }

        if(recurringDonation.InstallmentFrequency__c == 1) {
            if(recurringDonation.npe03__Installment_Period__c.isAlpha()) {
                if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
                    frequency = String.format(System.Label.frequencyPeriodOnTheDayOfTheMonth, new List<String>{recurringDonation.npe03__Installment_Period__c, mapDayOfMonth.get(recurringDonation.Day_of_Month__c).ToLowerCase()});
                } else {
                    frequency = recurringDonation.npe03__Installment_Period__c;
                }
            } else {
                frequency = String.format(System.Label.frequencyOnThePeriod, new List<String>{recurringDonation.npe03__Installment_Period__c});
            }
        } else {
            if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_MONTHLY) {
                frequency = String.format(System.Label.frequencyMonthly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c), mapDayOfMonth.get(recurringDonation.Day_of_Month__c).ToLowerCase()});
            } else if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_YEARLY) {
                frequency = String.format(System.Label.frequencyYearly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c)});
            } else if(recurringDonation.npe03__Installment_Period__c == RD2_Constants.INSTALLMENT_PERIOD_WEEKLY) {
                frequency = String.format(System.Label.frequencyWeekly, new List<String>{String.valueOf(recurringDonation.InstallmentFrequency__c)});
            }
        }

        if(frequency.right(1).isNumeric()) {
            switch on frequency.right(1) {
                when '1' {
                    frequency += System.Label.firstOrdinalNumber;
                }
                when '2' {
                    frequency += System.Label.secondOrdinalNumber;
                }
                when '3' {
                    frequency += System.Label.thirdOrdinalNumber;
                }
                when else {
                    frequency += System.Label.otherOrdinalNumber;
                }
            }
        }
        
        return frequency;
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donaion record to build the status string.
    * @param recurringDonation recurring dontation record
    * @return String returns the Status string.
    */
    private String getStatus(npe03__Recurring_Donation__c recurringDonation) {
        RD2_StatusMapper statusMapper = RD2_StatusMapper.getInstance();
        String status = '';

        Map<String, String> mapStatus = new Map<String, String>();
        for(Schema.PicklistEntry ple : Schema.SObjectType.npe03__Recurring_Donation__c.fields.Status__c.getPicklistValues()){
            mapStatus.put(ple.getValue(), ple.getLabel());
        }

        if(recurringDonation.Status__c == RD2_Constants.STATUS_PAUSED) {
            status = mapStatus.get(recurringDonation.Status__c);
        } else if(recurringDonation.Status__c != RD2_Constants.STATUS_PAUSED && statusMapper.getState(recurringDonation.Status__c) != RD2_Constants.STATUS_CLOSED) {
            status = statusMapper.getState(recurringDonation.Status__c);
        } else {
            status = STATUS_CANCELED;
        }

        return status;
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description process Recurring Donation record to build the payment method string.
    * @param recurringDonation recurring donation record
    * @return String returns the PaymentMethod string.
    */
    private String getPaymentMethod(npe03__Recurring_Donation__c recurringDonation) {
        String paymentMethod = '';

        if(String.IsBlank(recurringDonation.CommitmentId__c)) {
            //Non-Elevate RD
            paymentMethod = recurringDonation.PaymentMethod__c;
        
        } else {
            //Elevate RD
            if(recurringDonation.PaymentMethod__c == RD2_Constants.PAYMENT_PICKLIST_VALUE_CARD) {
                paymentMethod = String.format(System.Label.creditCardElevatePayment, new List<String>{recurringDonation.PaymentMethod__c, recurringDonation.CardLast4__c, recurringDonation.CardExpirationMonth__c, recurringDonation.CardExpirationYear__c});
            } else {
                paymentMethod = String.format(System.Label.achElevatePayment, new List<String>{recurringDonation.PaymentMethod__c, recurringDonation.ACH_Last_4__c});
            }
        }

        return paymentMethod;
    }

    /** 
    * @author Salesforce.org
    * @date 2022
    * @description method to check recurring donation permissions.
    * @return Boolean returns access to Recurring Donations.
    */
    private Boolean hasAccessToRecurringDonation() {
        return permissions.canRead(npe03__Recurring_Donation__c.SObjectType, new Set<SObjectField>{
            npe03__Recurring_Donation__c.npe03__Amount__c,
            npe03__Recurring_Donation__c.npe03__Installment_Period__c,
            npe03__Recurring_Donation__c.InstallmentFrequency__c,
            npe03__Recurring_Donation__c.Day_of_Month__c,
            npe03__Recurring_Donation__c.Status__c,
            npe03__Recurring_Donation__c.CommitmentId__c,
            npe03__Recurring_Donation__c.PaymentMethod__c,
            npe03__Recurring_Donation__c.CardLast4__c,
            npe03__Recurring_Donation__c.CardExpirationYear__c,
            npe03__Recurring_Donation__c.CardExpirationMonth__c,
            npe03__Recurring_Donation__c.ACH_Last_4__c
        });
    }
}