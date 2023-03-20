*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
...               Removes all temporary files after.

Library    RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.PDF
Library    RPA.Tables
Library    RPA.Archive
Library    RPA.FileSystem
Library    RPA.RobotLogListener

Task Setup       Setup
Task Teardown    Shutdown

*** Variables ***
${TEMP_FOLDER}=       ${OUTPUT_DIR}${/}temp
${TEMP_IMAGE}=        ${TEMP_FOLDER}${/}temp.png
${TEMP_PDF}=          ${TEMP_FOLDER}${/}temp.pdf
${TEMP_NAME}=         receipt_
${PATH}=              xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Fill orders
    Archive receipts

*** Keywords ***
Setup
    Create Directory          ${TEMP_FOLDER}
    Download                  https://robotsparebinindustries.com/orders.csv    overwrite=True
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Mute Run On Failure       Fill orders

Fill orders
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Order robot    ${order}
    END

Order robot
    [Arguments]    ${order}
    Wait Until Page Contains Element    id:root
    Click Button                        OK
    Wait Until Page Contains Element    id:head
    Fill form                           ${order}
    Click Button                        Preview
    Wait Until Keyword Succeeds         5x    100ms    Try to order
    Export the receipt as a PDF         ${order}
    Click Button                        id:order-another

Fill form
    [Arguments]    ${order}
    Select From List By Value   head       ${order}[Head]
    Select Radio Button         body       ${order}[Body]
    Input Text                  ${PATH}    ${order}[Legs]
    Input Text                  address    ${order}[Address]

Try to order
    Click Button      Order
    ${alertcheck}=    Does Page Contain Element    class:alert-danger    1
    IF    ${alertcheck} == True
        Fail
    END

Export the receipt as a PDF
    [Arguments]    ${order}
    ${OUT_PDF}=    Set Variable              ${TEMP_FOLDER}${/}${TEMP_NAME}${order}[Order number].pdf
    Wait Until Element Is Visible            id:receipt
    ${receipt}=    Get Element Attribute     id:receipt    outerHTML
    Screenshot     id:robot-preview-image    ${TEMP_IMAGE}
    HTML To PDF    ${receipt}    ${TEMP_PDF}
    Add Watermark Image To PDF    ${TEMP_IMAGE}    ${OUT_PDF}    ${TEMP_PDF}

Archive receipts
    Archive Folder With Zip
    ...    ${TEMP_FOLDER}
    ...    ${OUTPUT_DIR}${/}receipts.zip
    ...    include=${TEMP_NAME}*

Shutdown
    Remove Directory    ${TEMP_FOLDER}    recursive=True
    Close All Browsers