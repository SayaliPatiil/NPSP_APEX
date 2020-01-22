import { LightningElement, api } from 'lwc';
import { getQueryParameters } from 'c/utilCommon';
import { dispatch } from 'c/utilTemplateBuilder';
import TemplateBuilderService from 'c/geTemplateBuilderService';
import GeLabelService from 'c/geLabelService';

const EVENT_TOGGLE_MODAL = 'togglemodal';
const DEFAULT_FIELD_MAPPING_SET = 'Migrated_Custom_Field_Mapping_Set';
const GIFT_ENTRY_TAB_NAME = 'GE_Gift_Entry';
const GIFT_ENTRY = 'Gift_Entry';
const TEMPLATE_BUILDER = 'Template_Builder';
const SINGLE_GIFT_ENTRY = 'Single_Gift_Entry';

export default class geHome extends LightningElement {

    // Expose custom labels to template
    CUSTOM_LABELS = GeLabelService.CUSTOM_LABELS;

    view = GIFT_ENTRY;
    formTemplateId;
    cloneFormTemplate;
    donorId;
    giftEntryTabName;
    isLoading;

    get isLandingPage() {
        return this.view === GIFT_ENTRY ? true : false;
    }

    get isTemplateBuilder() {
        return this.view === TEMPLATE_BUILDER ? true : false;
    }

    get isSingleGiftEntry() {
        return this.view === SINGLE_GIFT_ENTRY ? true : false;
    }

    async connectedCallback() {
        this.isLoading = true;
        await TemplateBuilderService.init(DEFAULT_FIELD_MAPPING_SET);
        this.setGiftEntryTabName();
        this.setInitialView();
        this.isLoading = false;
    }

    /*******************************************************************************
    * @description Method sets the Gift Entry tab name with the proper namespace.
    */
    setGiftEntryTabName() {
        this.giftEntryTabName = TemplateBuilderService.alignSchemaNSWithEnvironment(GIFT_ENTRY_TAB_NAME);
    }

    /*******************************************************************************
    * @description Method handles setting the initial view based on url parameters
    * if there are any.
    */
    setInitialView() {
        const queryParameters = getQueryParameters();
        if (queryParameters && queryParameters.c__view) {
            this.view = queryParameters.c__view;
        }
    }

    /*******************************************************************************
    * @description Method handles changing the current view based on parameters
    * in the received event.
    *
    * @param {object} event: Event object containing parameters like 'c__view',
    * 'c__formTemplateRecordId', 'c__donorRecordId', etc used to change the current
    * view and set the respective view record id.
    */
    handleChangeView(event) {
        this.resetUrlParameters();

        this.view = event.detail.view;
        if (this.view === TEMPLATE_BUILDER && event.detail.formTemplateId) {
            this.formTemplateId = event.detail.formTemplateId;
            this.cloneFormTemplate = event.detail.clone;
        } else if (this.view === SINGLE_GIFT_ENTRY && event.detail.donorTypeId) {
            this.donorId = event.detail.donorTypeId;
        } else {
            this.formTemplateId = undefined;
            this.donorId = undefined;
        }
    }

    /*******************************************************************************
    * @description Method clears out any query parameters in the url.
    */
    resetUrlParameters() {
        window.history.pushState({}, document.title, this.giftEntryTabName);
    }

    /*******************************************************************************
    * @description Public method for receiving modal related events from geListView.
    *
    * @param {object} modalData: Event object containing the action and modal payload.
    * component chain: utilDualListbox -> geListView -> here.
    */
    @api
    notify(event) {
        if (event.receiverComponent && event.receiverComponent.length > 0) {
            const component = this.template.querySelector(`c-${event.receiverComponent}`);
            if (component) {
                component.notify(event);
            }
        }
    }

    /*******************************************************************************
    * @description Pass through method that receives an event from geListView to
    * notify parent aura component to construct a modal.
    *
    * @param {object} event: Event object containing a payload for the modal.
    */
    toggleModal(event) {
        dispatch(this, EVENT_TOGGLE_MODAL, event.detail);
    }
}