*** Settings ***
Resource        robot/Cumulus/resources/NPSP.robot
Library         cumulusci.robotframework.PageObjects
...             robot/Cumulus/resources/NPSPSettingsPageObject.py
...             robot/Cumulus/resources/GiftEntryPageObject.py
...             robot/Cumulus/resources/AdvancedMappingPageObject.py
Suite Setup     Run keywords
...             Open Test Browser
...             API Check And Enable Gift Entry
...             Setup Test Data

*** Keywords ***
Setup Test Data

*** Test Cases ***
Verify Custom Record Type ID Picklists Populate with Expected Values
    [Documentation]  Adds a Custom recordtypeID picklist, and verifies that all values are correctly set.
    [Tags]         unstable     feature:GE     W-8279315
