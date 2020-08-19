import { LightningElement, api } from 'lwc';
import BATCH_DATA_ENTRY_SETTING_RETIREMENT_ALERT from
       '@salesforce/schema/Batch_Data_Entry_Settings__c.Viewed_Retirement_Alert__c';
import getBatchDataEntrySettings from
       '@salesforce/apex/BDE_BatchEntry_CTRL.getBatchDataEntrySettings';
import upsertBatchDataEntrySettings from
       '@salesforce/apex/BDE_BatchEntry_CTRL.upsertBatchDataEntrySettings';
import { handleError } from 'c/utilTemplateBuilder';

export default class bdeRetirementAlert extends LightningElement {
   @api headerTitle;
   @api promptMessage;
   @api variant;
   @api hasBackDrop;
   @api confirmButtonTitle;
   @api confirmButtonVariant;
   @api position;
   showPrompt;


   connectedCallback() {
      getBatchDataEntrySettings()
      .then(response => {
         this.showPrompt =
             !response[BATCH_DATA_ENTRY_SETTING_RETIREMENT_ALERT.fieldApiName];
      }).catch(error =>{
         handleError(error);
      });
   }

   handleOnConfirm() {
      upsertBatchDataEntrySettings().then(response => {
         this.showPrompt = false;
      }).catch(error => {
         handleError(error)
      });
   }
}