/*
    Copyright (c) 2016, Salesforce.org
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
* @date 2016
* @group Households
* @group-content ../../ApexDocContent/Households.htm
* @description Lightning Component Server Controller for the Manage Household UI page
*/
public class HH_Container_LCTRL {

    /*******************************************************************************************************
    * @description trick the packaging spider to pickup references to custom labels only used by our
    * lightning components.
    */
    public static void packageLabels() {
        string str;
        str = Label.lblAddressOverride;
        str = Label.lblCCardExcludeFrom;
        str = Label.lblHouseholdName;
        str = Label.lblFormalGreeting;
        str = Label.lblInformalGreeting;
        str = Label.lblHousehold;
        str = Label.lblDeleteContact;
        str = Label.lblDeleteContactPrompt;
        str = Label.lblStreet;
        str = Label.lblCity;
        str = Label.lblState;
        str = Label.lblPostalCode;
        str = Label.lblCountry;
        str = Label.lblSalutation;
        str = Label.lblFirstName;
        str = Label.lblLastName;
        str = Label.stgBtnCancel;
        str = Label.stgBtnSave;
        str = Label.bdiBtnClose;
        str = Label.lblMergeHHTitle;
        str = Label.lblMergeHHPrompt;
        str = Label.lblBtnAddContact;
        str = Label.lblBtnAddAllHHMembers;

    }

    /*******************************************************************************************************
    * @description returns the Household object (Account or Custom Object) given the Id
    * @param hhId The Household's Id
    * @return SObject The Household Account or Custom Object
    */
    @AuraEnabled
    public static SObject getHH(ID hhId) {
        try {
            if (hhId == null)
                return null;
            string strSoql;
            if (UTIL_Describe.isObjectIdThisType(hhId, 'Account')) {
                strSoql = 'select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, ' +
                        UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c') + ', ' +
                        'BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingLatitude, BillingLongitude';

                /*** until we support these, we don't want them to interfere with what the user specifies.
                if (ADDR_Addresses_TDTM.isStateCountryPicklistsEnabled)
                    strSoql += ', BillingCountryCode, BillingStateCode ';
                ****/

                strSoql += ' from Account where Id = :hhId';
            } else {
                strSoql = 'select Id, Name, npo02__SYSTEM_CUSTOM_NAMING__c, npo02__Formal_Greeting__c, npo02__Informal_Greeting__c, ' +
                        UTIL_Namespace.StrTokenNSPrefix('Number_of_Household_Members__c') + ', ' +
                        'npo02__MailingStreet__c, npo02__MailingCity__c, npo02__MailingState__c, npo02__MailingPostalCode__c, npo02__MailingCountry__c ' +
                        ' from npo02__Household__c where Id = :hhId';
            }
            return database.query(strSoql);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description returns the Contacts for the given Household
    * @param hhId The Household's Id
    * @return list<Contact> The Contacts in the Household
    */
    @AuraEnabled
    public static list<Contact> getContacts(ID hhId) {
        try {
            if (hhId == null)
                return null;

            string strSoql = conSelect;

            // don't use contact.HHId in one soql since it can't use an index
            // and won't work in LDV orgs.
            if (UTIL_Describe.isObjectIdThisType(hhId, 'Account'))
                strSoql += ' where AccountId = :hhId ';
            else
                strSoql += ' where npo02__Household__c = :hhId ';

            strSoql += ' order by npo02__Household_Naming_Order__c, CreatedDate';

            return database.query(strSoql);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description returns the soql string to use to query contacts and their appropriate fields
    * @return String The soql select string to use for Contacts
    */
    private static string conSelect {
        get {
            if (conSelect == null) {
                //we use dynamic soql so we can include all contact fields, since custom naming may refer to any field.
                list<string> listStrField = getContactFields();
                string strSoql = 'SELECT ';
                string strComma = '';
                for (string strF : listStrField) {
                    strSoql += strComma + strF;
                    strComma = ',';
                }
                strSoql += ' FROM Contact ';
                conSelect = strSoql;
            }
            return conSelect;
        }
        set;
    }

    /*******************************************************************************************************
    * @description returns a list of Contact Fields (developer name)
    * @return list<String> the list of Contact Fields
    */
    private static list<String> getContactFields() {
        try {
            set<String> setContactFields = new Set<String>{'Id', 'npo02__Household_Naming_Order__c', 'FirstName', 'LastName', 'Salutation', 'Name',
                'npo02__Naming_Exclusions__c', 'npo02__Household__c', 'AccountId', 'HHId__c',
                'Exclude_from_Household_Name__c', 'Exclude_from_Household_Formal_Greeting__c', 'Exclude_from_Household_Informal_Greeting__c',
                'is_Address_Override__c', 'Current_Address__c', 'npe01__Primary_Address_Type__c',
                'MailingStreet', 'MailingCity', 'MailingState', 'MailingPostalCode', 'MailingCountry', 'MailingLatitude', 'MailingLongitude', 'CreatedDate'};

                /*** until we support these, we don't want them to interfere with what the user specifies.
                if (ADDR_Addresses_TDTM.isStateCountryPicklistsEnabled)
                    strSoql += ', MailingCountryCode, MailingStateCode ';
                ******/

            setContactFields.addAll(HH_HouseholdNaming.iNaming.setHouseholdNameFieldsOnContact());
            return new list<String>(setContactFields);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description saves any changes to the Contacts in the database
    * @param listCon The list of Contacts to save
    * @return void
    */
    @AuraEnabled
    public static void upsertContacts(list<Contact> listCon) {
        try {
            // even though we are given a list of Contacts from the lightning component,
            // apex seems to treat them as generic sObjects, and thus we can't do upsert.
            // thus we will split the list into update and insert lists.
            list<Contact> listInsert = new list<Contact>();
            list<Contact> listUpdate = new list<Contact>();
            for (Contact con : listCon) {
                if (con.Id != null)
                    listUpdate.add(con);
                else
                    listInsert.add(con);
            }
            // allow potential duplicates when rules to warn are turned on.
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            list<Database.SaveResult> listSR = Database.insert(listInsert, dml);
            for (Database.SaveResult sr : listSR) {
                if (!sr.isSuccess())
                    throw new DmlException(sr.getErrors()[0].getMessage());
            }
            update listUpdate;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description deletes the Contacts in the database
    * @param listCon The list of Contacts to delete
    * @return void
    */
    @AuraEnabled
    public static void deleteContacts(list<Contact> listCon) {
        try {
            delete listCon;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description saves any changes to the Household in the database
    * @param hh The Household
    * @return void
    */
    @AuraEnabled
    public static void updateHousehold(SObject hh) {
        try {
            // we've already saved the data for the contacts in the household.
            // now we only need to save the account fields an update, and we don't want
            // any of the normal account trigger work to run again.  specifically,
            // we may have updated the names and greetings, because the contacts have changed,
            // but the user still may want auto-naming turned on.  our normal trigger flow
            // would think the user updated the name from what it was, and thus it should be
            // excluded from auto-naming!
            HH_ProcessControl.inFutureContext = true;

            update hh;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description merge the list of household Accounts into the winning household
    * @param hh The winning Household
    * @param listHHMerge the list of Households to merge into the winner
    * @return void
    */
    @AuraEnabled
    public static void mergeHouseholds(Account hhWinner, list<Account> listHHMerge) {
        try {
            for (Account loser : listHHMerge)
                merge hhWinner loser;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description sets the Household Name and Greetings on the Household object, given the list of Contacts
    * @param hh The Household Object (Account or Custom Object) to set the names on
    * @param listCon The list of Contacts to use
    * @return SObject the Household object
    */
    @AuraEnabled
    public static SObject getHHNamesGreetings(SObject hh, list<Contact> listCon) {
        try {
            // update naming exclusions field based on exclusion checkboxes
            for (Contact con : listCon)
                HH_Households_TDTM.copyNamingExclusionsFromCheckboxes(con);

            HH_HouseholdNaming hn = new HH_HouseholdNaming();
            String strExclusions = (String)hh.get('npo02__SYSTEM_CUSTOM_NAMING__c');
            if (strExclusions == null)
                strExclusions = '';
            if (!strExclusions.contains('Name'))
                hh.put('Name', hn.getHHName(listCon));
            if (!strExclusions.contains('Formal_Greeting__c'))
                hh.put('npo02__Formal_Greeting__c', hn.getFormalName(listCon));
            if (!strExclusions.contains('Informal_Greeting__c'))
                hh.put('npo02__Informal_Greeting__c', hn.getInformalName(listCon));
            return hh;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description returns the Addresses for the given Household.  note that it returns Address objects,
    * even when dealing with Household Objects (in which case it creates in memory address objects for each
    * contact's mailing address).
    * @param hhId The Household's Id
    * @param listAddrExisting the list of existing addresses
    * @return list<Address__c> The addresses in the household and contacts
    */
    @AuraEnabled
    public static list<Address__c> getAddresses(ID hhId, list<Address__c> listAddrExisting) {
        try {
            if (hhId == null)
                return null;

            // keep unique list of addresses in temp Address objects
            list<Address__c> listAddr = new list<Address__c>();
            set<String> setAddrKey = new set<String>();

            // if they provide existing addresses, do our initialization
            if (listAddrExisting != null) {
                for (Address__c addr : listAddrExisting) {
                    listAddr.add(addr);
                    setAddrKey.add(ADDR_Addresses_TDTM.getAddrKey(addr));
                }
            }

            // load our Household and Contacts
            // CONSIDER: since the client also loads the hh and contacts, we could
            // put in a static cache to avoid requerying if they are already loaded.
            // ie, track a static hh and with hhId it came from, and use it in getHH()
            // if the hhId matches.  Same with listCon.
            SObject hh = getHH(hhId);
            list<Contact> listCon = getContacts(hhid);

            // copy the household's address
            Address__c addr = new Address__c();
            if (UTIL_Describe.isObjectIdThisType(hhId, 'Account')) {
                addr = new Address__c();
                // can't use our utility routine, because we specifically are not querying for StateCode & CountryCode
                // to avoid those saved codes from interfering with the user's changes (that won't include the codes)
                //ADDR_Addresses_TDTM.copyAddressStdSObjAddr(hh, 'Billing', addr, null);
                addr.MailingStreet__c = (String)hh.get('BillingStreet');
                ADDR_Addresses_TDTM.handleMultilineStreet(addr);
                addr.MailingCity__c = (String)hh.get('BillingCity');
                addr.MailingState__c = (String)hh.get('BillingState');
                addr.MailingPostalCode__c = (String)hh.get('BillingPostalCode');
                addr.MailingCountry__c = (String)hh.get('BillingCountry');
            } else {
                addr.MailingStreet__c = (String)hh.get('npo02__MailingStreet__c');
                addr.MailingCity__c = (String)hh.get('npo02__MailingCity__c');
                addr.MailingState__c = (String)hh.get('npo02__MailingState__c');
                addr.MailingPostalCode__c = (String)hh.get('npo02__MailingPostalCode__c');
                addr.MailingCountry__c = (String)hh.get('npo02__MailingCountry__c');
            }
            if (listAddrExisting == null)
                addr.Default_Address__c = true;  // the HH address is the default.
            String strKey = ADDR_Addresses_TDTM.getAddrKey(addr);
            if (setAddrKey.add(strKey))
                listAddr.add(addr);

            // copy the contacts' addresses
            for (Contact con : listCon) {
                addr = new Address__c();
                // can't use our utility routine, because we specifically are not querying for StateCode & CountryCode
                // to avoid those saved codes from interfering with the user's changes (that won't include the codes)
                //ADDR_Addresses_TDTM.copyAddressStdSObjAddr(con, 'Mailing', addr, null);
                addr.MailingStreet__c = con.MailingStreet;
                ADDR_Addresses_TDTM.handleMultilineStreet(addr);
                addr.MailingCity__c = con.MailingCity;
                addr.MailingState__c = con.MailingState;
                addr.MailingPostalCode__c = con.MailingPostalCode;
                addr.MailingCountry__c = con.MailingCountry;
                strKey = ADDR_Addresses_TDTM.getAddrKey(addr);
                if (setAddrKey.add(strKey))
                    listAddr.add(addr);
            }

            // copy any address objects
            if (UTIL_Describe.isObjectIdThisType(hhId, 'Account')) {
                list<Address__c> listAddrHH = [select MailingStreet__c, MailingStreet2__c, MailingCity__c, MailingState__c, MailingPostalCode__c, MailingCountry__c
                    from Address__c where Household_Account__c = :hhId];
                for (Address__c addrT : listAddrHH) {
                    // init other values we don't want to query for that the key might use.
                    addrT.Seasonal_Start_Day__c = null;
                    addrT.Seasonal_Start_Month__c = null;
                    addrT.Seasonal_End_Day__c = null;
                    addrT.Seasonal_End_Month__c = null;
                    addrT.Address_Type__c = null;
                    strKey = ADDR_Addresses_TDTM.getAddrKey(addrT);
                    if (setAddrKey.add(strKey))
                        listAddr.add(addrT);
                }
            }

            return listAddr;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description adds the Contact's addresses to the provided list, ensuring uniqueness. note that it returns Address objects,
    * even when dealing with Household Objects (in which case it creates in memory address objects for each
    * contact's mailing address).
    * @param listCon the list of Contacts
    * @param listAddrExisting the list of existing addresses
    * @return list<Address__c> The addresses in the household and contacts
    */
    @AuraEnabled
    public static list<Address__c> addContactAddresses(list<Contact> listCon, list<Address__c> listAddrExisting) {
        try {
            if (listCon == null)
                return null;

            // keep unique list of addresses in temp Address objects
            list<Address__c> listAddr = new list<Address__c>();
            set<String> setAddrKey = new set<String>();

            // if they provide existing addresses, do our initialization
            if (listAddrExisting != null) {
                for (Address__c addr : listAddrExisting) {
                    listAddr.add(addr);
                    setAddrKey.add(ADDR_Addresses_TDTM.getAddrKey(addr));
                }
            }

            // copy the contacts' addresses
            for (Contact con : listCon) {
                Address__c addr = new Address__c();
                // can't use our utility routine, because we specifically are not querying for StateCode & CountryCode
                // to avoid those saved codes from interfering with the user's changes (that won't include the codes)
                //ADDR_Addresses_TDTM.copyAddressStdSObjAddr(con, 'Mailing', addr, null);
                addr.MailingStreet__c = con.MailingStreet;
                ADDR_Addresses_TDTM.handleMultilineStreet(addr);
                addr.MailingCity__c = con.MailingCity;
                addr.MailingState__c = con.MailingState;
                addr.MailingPostalCode__c = con.MailingPostalCode;
                addr.MailingCountry__c = con.MailingCountry;
                string strKey = ADDR_Addresses_TDTM.getAddrKey(addr);
                if (setAddrKey.add(strKey))
                    listAddr.add(addr);
            }

            return listAddr;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description returns the Salutation choices on Contact
    * @return list<SelectOption> The Salutations
    */
    @AuraEnabled
    public static list<SelectOption> getSalutations() {
        try {

            List<Schema.PicklistEntry> picklistSalutations = Contact.Salutation.getDescribe().getPicklistValues();
            List<SelectOption> listSalutations = new List<SelectOption>();

            listSalutations.add(new SelectOption(Label.stgLabelNone, null));
            for (Schema.PickListEntry entry : picklistSalutations) {
                listSalutations.add(new SelectOption(entry.getLabel(), entry.getValue()));
            }
            return listSalutations;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*******************************************************************************************************
    * @description represents a select option, providing members for label and value.
    */
    public class SelectOption {

        public SelectOption(string strLabel, string strValue) {
            label = strLabel;
            value = strValue;
        }

        @AuraEnabled
        public string label { get; set; }

        @AuraEnabled
        public string value { get; set; }
    }

}