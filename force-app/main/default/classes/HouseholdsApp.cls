/*
    Copyright (c) 2021 Salesforce.org
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
* @date 2021
* @description Top-level Application class for Households functionality in NPSP.
*/
public inherited sharing class HouseholdsApp {

    @TestVisible
    private ContactSelector contactSelector {
        get {
            if (contactSelector == null) {
                contactSelector = new ContactSelector();
            }
            return contactSelector;
        }
        set;
    }

    @TestVisible
    private HouseholdAccountSelector householdAccountRepository {
        get {
            if (householdAccountRepository == null) {
                householdAccountRepository =
                        new HouseholdAccountSelector();
            }
            return householdAccountRepository;
        }
        set;
    }

    public void onBeforeInsertOf(Accounts accounts) {
        if (isAddressManagementEnabled()) {
            normalizeLineBreaksFor(accounts.householdAccounts());
        }
        if (isOrgAccountAddressesEnabled()) {
            normalizeLineBreaksFor(accounts.orgAccounts());
        }
    }

    public void onAfterInsertOf(Accounts accounts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        createNewAddressesAndAddToDmlWrapperForProcessing(accounts, dmlWrapper);
    }

    private void createNewAddressesAndAddToDmlWrapperForProcessing(Accounts accounts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Account> listAccCreateAddr = new List<Account>();
        if (isAddressManagementEnabled()) {
            listAccCreateAddr.addAll(accounts.withAddresses().householdAccounts());
        }
        if (isOrgAccountAddressesEnabled()) {
            listAccCreateAddr.addAll(accounts.withAddresses().orgAccounts());
        }
        // create any new Address objects
        if (listAccCreateAddr.size() > 0) {
            createAddrFromAcc(listAccCreateAddr, dmlWrapper);
        }
    }

    /*******************************************************************************************************
    * @description for each Account, create a new default address and add it to dmlWrapper
    * @param listAcc a list of Accounts
    * @param dmlWrapper to hold the Addresses that need creating
    ********************************************************************************************************/
    private void createAddrFromAcc(List<Account> listAcc,
            TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Address__c> listAddr = new List<Address__c>();
        for (Account acc : listAcc) {
            NPSP_Address npspAddress = new NPSP_Address(acc);
            listAddr.add(npspAddress.getRecord());
        }
        // since coming from an account address, there is no Address Type, so exclude it from the match testing.
        Addresses.createNonDuplicateAddresses(listAddr, dmlWrapper, false);
    }

    public void onBeforeUpdateOf(Accounts accounts) {
        if (isAddressManagementEnabled()) {
            normalizeLineBreaksFor(
                    accounts.withBillingAddressChanges().householdAccounts()
            );
        }
        if (isOrgAccountAddressesEnabled()) {
            normalizeLineBreaksFor(
                    accounts.withBillingAddressChanges().orgAccounts()
            );
        }
    }

    public void onAfterUpdateOf(Accounts accounts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        // note that we detect whether the change is coming from the address trigger,
        // in which case we don't want to create a new address.
        if (TDTM_ProcessControl.isRecursive(
                TDTM_ProcessControl.flag.ADDR_hasRunTrigger)) {
            UTIL_Debug.debug('**** RECURSION: ' +
                    'Stop Addr Trigger recursion in ADDR_Account_TDTM');
            return;
        }

        List<Account> listAccCreateAddr = new List<Account>();
        if (isAddressManagementEnabled()) {
            listAccCreateAddr.addAll(accounts.withBillingAddressChanges().householdAccounts());
        }
        if (isOrgAccountAddressesEnabled()) {
            listAccCreateAddr.addAll(accounts.withBillingAddressChanges().orgAccounts());
        }
        // create any new Address objects
        if (listAccCreateAddr.size() > 0) {
            createAddrFromAcc(listAccCreateAddr, dmlWrapper);
        }
    }

    public void onBeforeInsertOf(Contacts contacts) {
        contacts.resetDeprecatedFields();

        HouseholdAccounts.createOneToOneAndHouseholdAccountsFor(
                //todo: pull out settings check
                (List<Contact>) contacts.contactsAndOneToOneContacts_insertContext()
                        .getRecords());

        Households.addToBucketAccount(contacts);
    }

    public void onAfterInsertOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields(contacts);

        Households.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        HouseholdAccounts.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    /**
     * @description In the before update trigger context, ensure accounts are created for the contacts that need them.
     */
    public void onBeforeUpdateOf(Contacts contacts) {
        Households.handleContactsBeforeUpdate(contacts);
    }

    public void onAfterUpdateOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                new ContactSelector().getContactsWithAccountAndAddressFields(
                        contacts.getRecords());
        Households.handleContactsAfterUpdate(
                new Contacts(contactsWithAccountAndAddressFields, contacts.oldMap.values()),
                dmlWrapper);
    }

    public void onAfterDeleteOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        HouseholdAccounts householdAccounts = getHouseholdsFor(contacts.accountIds());
        householdAccounts.handleContactDeletion(dmlWrapper);
    }

    public void onAfterUndeleteOf(Contacts contacts, TDTM_Runnable.DmlWrapper dmlWrapper) {
        List<Contact> contactsWithAccountAndAddressFields =
                getContactsWithAccountAndAddressFields(contacts);

        Households.updatePrimaryContactOnAccountsAfterInsert(
                dmlWrapper, contactsWithAccountAndAddressFields);

        HouseholdAccounts.renameHouseholdAccountsAfterInsert(
                contactsWithAccountAndAddressFields);
    }

    private List<Contact> getContactsWithAccountAndAddressFields(Contacts contacts) {
        List<Contact> contactsWithAccountAndAddressFields =
                contactSelector.getContactsWithAccountAndAddressFields(contacts.getRecords());
        return contactsWithAccountAndAddressFields;
    }

    private HouseholdAccounts getHouseholdsFor(Set<Id> ids) {
        return householdAccountRepository.findByIdWithOneContactAndGift(ids);
    }

    private Boolean isAddressManagementEnabled() {
        if (!UTIL_CustomSettingsFacade.getContactsSettings().Household_Account_Addresses_Disabled__c) {
            return true;
        }
        return false;
    }

    private Boolean isOrgAccountAddressesEnabled() {
        if (UTIL_CustomSettingsFacade.getContactsSettings().Organizational_Account_Addresses_Enabled__c) {
            return true;
        }
        return false;
    }

    private void normalizeLineBreaksFor(List<SObject> listNew) {
        for (Integer i = 0; i < listNew.size(); i++) {
            Account newRecord = (Account) listNew[i];
            UTIL_Address.normalizeLineBreak(newRecord);
        }
    }

}