/*
 * Copyright (c) 2020 Salesforce.org
 *     All rights reserved.
 *
 *     Redistribution and use in source and binary forms, with or without
 *     modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Salesforce.org nor the names of
 *       its contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *     "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *     LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 *     FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 *     COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 *     INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 *     BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *     CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *     LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 *     ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *     POSSIBILITY OF SUCH DAMAGE.
 */
import { LightningElement } from 'lwc';
import { handleError } from 'c/utilTemplateBuilder';
import messageLoading from '@salesforce/label/c.labelMessageLoading';
import setGatewayId from '@salesforce/apex/PS_GatewayManagement.setGatewayId';
import getGatewayIdFromConfig from '@salesforce/apex/PS_GatewayManagement.getGatewayIdFromConfig';

export default class GePaymentGatewayManagement extends LightningElement {

    showSpinner = false;
    gatewayId;

    CUSTOM_LABELS = { messageLoading };

    connectedCallback() {
        this.getGatewayId();
    }

    _isReadState = true;
    get isReadState() {
        return this._isReadState;
    }
    set isReadState(value) {
        this._isReadState = value;
        this._isEditState = false;
    }

    _isEditState;
    get isEditState() {
        return this._isEditState
    }
    set isEditState(value) {
        this._isEditState = value;
        this._isReadState = false;
    }

    _isSuccess;
    get isSuccess() {
        return this._isSuccess;
    }
    set isSuccess(value) {
        this._isSuccess = value;

        if (value) { this.isError = false; }
    }

    _isError;
    get isError() {
        return this._isError;
    }
    set isError(value) {
        this._isError = value;

        if (value) { this.isSuccess = false; }
    }

    _errorMessage;
    get errorMessage() {
       return this._errorMessage;
    }
    set errorMessage(value) {
        this._errorMessage = value;
    }

    handleEdit() {
        this.isEditState = true;
    }

    handleCancel() {
        this.isReadState = true;
    }

    async handleSave(event) {
        try {
            let gatewayId = this.template.querySelector("[data-id='gatewayIdEditField']").value;
            await setGatewayId({ gatewayId: gatewayId});

            this.isSuccess = true;
        } catch(ex) {
            console.log(ex);
            this.isError = true;
        }
    }

    async getGatewayId() {
        try {
            this.gatewayId = await getGatewayIdFromConfig();
        } catch(ex) {
            // handleError(ex);
        }
    }
}
