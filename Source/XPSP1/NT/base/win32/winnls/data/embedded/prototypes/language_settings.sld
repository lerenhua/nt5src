<?xml version="1.0" encoding="UTF-16"?>
<!DOCTYPE DCARRIER SYSTEM "Mantis.DTD">

  <DCARRIER
    CarrierRevision="1"
    DTDRevision="16"
  >
    <TASKS
      Context="1"
      PlatformGUID="{00000000-0000-0000-0000-000000000000}"
    >    </TASKS>

    <PLATFORMS
      Context="1"
    >    </PLATFORMS>

    <REPOSITORIES
      Context="1"
      PlatformGUID="{00000000-0000-0000-0000-000000000000}"
    >    </REPOSITORIES>

    <GROUPS
      Context="1"
      PlatformGUID="{00000000-0000-0000-0000-000000000000}"
    >    </GROUPS>

    <COMPONENTS
      Context="1"
      PlatformGUID="{00000000-0000-0000-0000-000000000000}"
    >
      <COMPONENT
        ComponentVSGUID="{F6FACD36-89A8-49AB-9C59-8C054F209DAE}"
        ComponentVIGUID="{A0275FEA-EA5E-4BF8-9864-F9B6EC4B0F2F}"
        Revision="724"
        RepositoryVSGUID="{8E0BE9ED-7649-47F3-810B-232D36C430B4}"
        Visibility="1000"
        MultiInstance="False"
        Released="False"
        Editable="True"
        HTMLTitle="Regional and Language Options"
        HTMLFinal="False"
        IsMacro="False"
        Opaque="False"
        Context="1"
        PlatformGUID="{B784E719-C196-4DDB-B358-D9254426C38D}"
      >
        <SCRIPTTEXT
          language="VBScript"
          src=".\language_settings.vbs"
          encoded="False"
        ><![CDATA['////////////////////////////////////////////////////////////////////////////
' $Header:$
' Windows Embedded Regional And Language Settings Component Script
' Version: 1.00
' Author: sjang
' Copyright (c) 1999-2001 Microsoft Corp. All Rights Reserved.
'////////////////////////////////////////////////////////////////////////////

'**************************************************************************************************************************
' CONSTANTS AND GLOBAL VARIABLES
'**************************************************************************************************************************
Option Explicit

Public Const guidLangSupportGroup = "{A1A56917-46F2-492E-A544-C4EB1B95F61E}"
Public Const cGeoRegKey = "HKEY_USERS\.DEFAULT\Control Panel\International\Geo"

'
' Default UI Language Fallback settings
'
Public Const cLanguageEnglish = 9
Public Const cSLocaleEnglishUSA = 1033
Public Const cLocationUSA = 244

Dim oPL : Set oPL = cmiThis.Configuration.Script.oPL
Dim oLangOptions : Set oLangOptions = New LanguageConfigData

'**************************************************************************************************************************
' ULITITY FUNCTIONS
'**************************************************************************************************************************

'////////////////////////////////////////////////////////////////////////////
' vuQuickSort
' The standard quick sort algorithm. This code sorts any collection via the
' usual "swap" and "compare" user-supplied functions. As examples, vuDefComp
' and vuDefSwap (following) are provided for sorting arrays of variants, but
' any collection or partial collection can be sorted using this function.
'
' vData				Data item to pass to swap & compare functions
' nLeftIndex		Index of first item to sort (use LBound for all)
' nRightIndex		Index of last item to sort (use UBound for all)
' oCompFunc			User compare routine (via GetRef)
' oSwapFunc			User swap function (via GetRef)
'
'Sub vuQuickSort(ByRef vData, nLeftIndex, nRightIndex, oCompFunc, oSwapFunc)
'	Dim nPivot, ix
'	If nLeftIndex >= nRightIndex Then Exit Sub	' Recurse end test
'	nPivot = nLeftIndex							' Start pivot point
'	For ix = nLeftIndex + 1 To nRightIndex		' Scan array
'		If oCompFunc(vData, ix, nLeftIndex) < 0  Then	' If swap..
'			nPivot = nPivot + 1					' Make room in LHS
'			oSwapFunc vData, nPivot, ix			' Swap the data
'		End If
'	Next
'	oSwapFunc vData, nPivot, nLeftIndex			' Move pivot to final
'	vuQuickSort vData, nLeftIndex, nPivot - 1, oCompFunc, oSwapFunc
'	vuQuickSort vData, nPivot + 1, nRightIndex, oCompFunc, oSwapFunc
'End Sub
'

Function vuDefComp(ByRef vData, nLeft, nRight)
	Select Case VarType(vData(nLeft))
		Case vbString
			vuDefComp = StrComp(vData(nLeft), vData(nRight), vbTextCompare)
		Case Else
			vuDefComp = vData(nLeft) - vData(nRight)	' Subtract numbers etc
	End Select
End Function

Sub vuDefSwap(ByRef vData, nLeft, nRight)
	Dim vTemp
	If IsObject(vData(nLeft)) Then
		Set vTemp = vData(nLeft)				' Swap objects
		Set vData(nLeft) = vData(nRight)
		Set vData(nRight) = vTemp
	Else
		vTemp = vData(nLeft)					' Swap data
		vData(nLeft) = vData(nRight)
		vData(nRight) = vTemp
	End If
End Sub

'**************************************************************************************************************************
' CLASSES TO BE USED INTERNALLY AND EXTERNALLY
'**************************************************************************************************************************

Class NameAndValue
   Public Name             ' string to display
   Public Value            ' numeric value
End Class
'
' Compare name function used to sort NameAndValue by vuQuickSort
'
' vData     Data collection to sort
' nLeft		Left item index
' nRight		Right item index
' Returns	0 if equal, 1 if left > right, -1 if left < right
'
Function CompareName(ByRef vData, nLeft, nRight)	' Flipped for descending
	CompareName = StrComp(vData(nLeft).Name, vData(nRight).Name, vbTextCompare)
End Function


'////////////////////////////////////////////////////////////////////////////
' LanguageConfigData
' Class that contains all the answers to questions from our DHTML.
'
' Init(oInst)           - initialize the object. Mainly, this function constructs
'                         the list of available geographical locations. 
' InitLocaleList        - initialize the object with the current state of
'                         configuration. oHostInst is always cmiThis.
' SetDefaultLangId      - set default UI language ID
'                         this affects available system locale list
'
Class LanguageConfigData

   Public nDefaultLangId         ' current UI language ID
                                 ' (0 indicates no support present)
   Public nDefaultULocale        ' current user locale ID
   Public nDefaultILocale        ' current input locale ID
   Public nDefaultSLocale        ' current system locale ID
   Public nDefaultLocation       ' current geographical location ID
   
   Public nFallbackLangId        ' Fallback UI language (if no Mui resource available)
   Public nFallbackLangName      ' The name of the fallback UI language
   Public nFallbackSLocale       ' Fallback system locale (if no Mui resource available)
   
   Public aLangIDs               ' available UI language IDs (NameAndValue objects)
   Public aLocations             ' available geographical location IDs (NameAndValue objects)
   '
   ' Array of LocaleData defined in language support prototype script
   ' 
   Public aULocales              ' available user locale IDs
   Public aILocales              ' available input locale IDs
   Public aSLocales              ' available system locale IDs
                                 ' (limited by nDefaultLangID)
   
   Public oLS                    ' LanguageSupportData object from a random
                                 ' language support instance
   Public oAL                    ' AvailableLocales object from a random
                                 ' language support instance               
   Private m_oInst               ' host instance
   Private m_oConfig

   '////////////////////////////////////////////////////////////////////////////
   ' Init
   ' Initialize the minimum number of member variables, and also a list of
   ' available geographical locations. This is called once at instance
   ' activation time.
   '
   ' oHostInst - Regional and Language Settings component instance
   '
   Sub Init(oHostInst)
      Dim oProp
      Dim aGeo
      Dim i
      '
      ' Construct location array
      '
      Set m_oInst = oHostInst
      Set m_oConfig = oHostInst.Configuration
      
      nFallbackLangId = cLanguageEnglish     ' fallback to English
      nFallbackLangName = "English"          ' name of the fallback language
      nFallbackSLocale = cSLocaleEnglishUSA  ' fallback to English (United States)
      
      '
      ' Get the default location
      '
      If m_oConfig.Properties.Exists("cmiLangDefaultLocation") Then
         Set oProp = m_oConfig.Properties.Item("cmiLangDefaultLocation")
         nDefaultLocation = oProp.Value
      Else
         '
         ' Use fallback location if the property doesn't exist
         '
         nDefaultLocation = cLocationUSA
         Set oProp = oPL.CreateProp("cmiLangDefaultLocation",cmiInteger,cLocationUSA)
         m_oConfig.Properties.Add oProp
      End If
      '
      ' Construct the available language array
      '
      aLangIDs = Array()
      aLocations = Array()
      i = 0
      For Each oProp In oHostInst.Properties
         If InStr(1, oProp.Name, "cmiLangGeoLocation", vbTextCompare) = 1 Then
            If oProp.Format <> cmiString Then
               Err.Raise oLS.Script.errLangInvalidPropertyFormat, _
                         "[Regional and Language Optons]", _
                         oProp.Name & " does not contain valid property format."
            End If
            aGeo = Split(oProp.Value, ";") ' aGeo(0) - name; aGeo(1) = Id
            If (UBound(aGeo) = 0) Or _
               Not IsNumeric(aGeo(1)) Then
               Err.Raise oLS.Script.errLangInvalidPropertyValue, _
                         "[Regional and Language Optons]", _
                         oProp.Name & " does not contain valid property value."
            End If
            ReDim Preserve aLocations(i)
            Set aLocations(i) = New NameAndValue
            aLocations(i).Name = aGeo(0)
            aLocations(i).Value = CLng(aGeo(1))
            i = i + 1
         End If
      Next
      vuQuickSort aLocations, LBound(aLocations), UBound(aLocations), GetRef("CompareName"), GetRef("vuDefSwap")
   End Sub

   '////////////////////////////////////////////////////////////////////////////
   ' InitLocaleList
   ' Based on state of the current configuration, initialize available locales
   ' and UI language list. We need to reinitialize this structure on every configuration
   ' event since things can change any time.
   '
   Public Sub InitLocaleList
      Dim oHostInst : Set oHostInst = m_oInst
      Dim oConfig : Set oConfig = m_oConfig
      Dim oInst
      Dim i, j
      Dim oProp
      '
      ' Start from scratch
      '
      Set oLS = Nothing
      Set oAL = Nothing
      '
      ' Find a language support component that contains MUI resources and
      ' Mui resource is enabled for it.
      ' If there is no such component, we cannot set the system locale,
      ' and therefore we cannot configure regional and language options.
      ' In that case, bail out.
      '
      nDefaultLangId = 0
      If Not oPL.GToI.PrimaryExists(guidLangSupportGroup) Then Exit Sub
      Dim aLSInst
      aLSInst = oPL.GToI.Keys(guidLangSupportGroup)
      For i = 0 To UBound(aLSInst)
         Set oInst = oConfig.Instances.Item(aLSInst(i))
         Set oLS = oInst.Script.oLS
         If Not IsEmpty( oLS.guidMuiComponent ) And _
            oLS.IsMuiEnabled( oInst ) Then
            Exit For
         End If
         ' reset the instance and language support data object
         Set oInst = Nothing
         Set oLS = Nothing
      Next
      If oInst Is Nothing Then Exit Sub
      Set oAL = oInst.Script.oAL
      '
      ' We found a language support component. This means that the
      ' current configuration contains all extended properties
      ' required by locale settings.
      '
      nDefaultLangId = oLS.GetProp(oConfig,"cmiLangDefaultUILanguage").Value
      nDefaultULocale = oLS.GetProp(oConfig,"cmiLangDefaultUserLocale").Value
      nDefaultILocale = oLS.GetProp(oConfig,"cmiLangDefaultInputLocale").Value
      nDefaultSLocale = oLS.GetProp(oConfig,"cmiLangDefaultSystemLocale").Value
      nDefaultLocation = oLS.GetProp(oConfig,"cmiLangDefaultLocation").Value
      '
      ' Construct AvailableLocales object again based on current
      ' configuration state. Then create aLangIds array.
      '
      oAL.Construct(oConfig)
      '
      ' Also compile a list of language IDs available for default UI language.
      ' This list is only populated by components that have associated
      ' MUI resource component AND if the user selected to bring in the MUI
      ' resource. We are not writing special case code for English here, even
      ' though, for XP, we know that we will always have English resources.
      ' Instead, we make use of fallback language settings.
      '
      Dim oILS
      j = 0
      For i = 0 To UBound(aLSInst)
         Set oInst = oConfig.Instances.Item(aLSInst(i))
         Set oILS = oInst.Script.oLS
         If Not IsEmpty(oILS.guidMuiComponent) And _
            oLS.GetProp(oInst,"cmiLangEnableMui").Value Then
            '
            ' The instance has associated Mui resource component
            ' and is allowed to bring in UI resources.
            '
            ReDim Preserve aLangIds(j)
            Set aLangIds(j) = New NameAndValue
            aLangIds(j).Name = oILS.sLangName
            aLangIds(j).Value = oILS.nLangId
            j = j + 1
         End If
      Next
      If j = 0 Then
         '
         ' Use fallback language here
         '
         ReDim Preserve aLangIds(j)
         Set aLangIds(j) = New NameAndValue
         aLangIds(j).Name = nFallbackLangName
         aLangIds(j).Value = nFallbackLangId
      Else
         vuQuickSort aLangIds, LBound(aLangIds), UBound(aLangIds), GetRef("CompareName"), GetRef("vuDefSwap")
      End If
      aULocales = oAL.AvailableULocales
      aILocales = oAL.AvailableULocales
      '
      ' We indirectly set aSLocales by calling SetDefaultLangId in order to
      ' guarantee that there is at least one default system locale set.
      ' (aSLocales is set in this routine)
      '
      SetDefaultLangId(nDefaultLangId)
   End Sub

   '////////////////////////////////////////////////////////////////////////////
   ' SetDefaultLangId
   ' Set a different default UI language ID.
   ' This limits the available system locale list (we force the system locales
   ' and default UI language to match). This routine modifies extended
   ' properties to reflect the new lang ID and default system locale settings.
   '
   ' When calling this function, the caller should do the following:
   ' 1. update its available system locale list by getting the list again from
   '    aSLocales after this call returns.
   ' 2. update the current locale selection by getting nDefaultSLocale
   '
   ' nLangId      - Language ID
   '
   Public Sub SetDefaultLangId(nLangId)
      Dim oProp
      If nDefaultLangId <> nLangId Then
         nDefaultLangId = nLangId
         Set oProp = oLS.GetProp(m_oConfig, "cmiLangDefaultUiLanguage")
         If Not oProp Is Nothing Then oProp.Value = nLangId
      End If
      '
      ' This property gets created when the very first language support
      ' component gets activated.
      '
      Set oProp = oLS.GetProp(m_oConfig, "cmiLangDefaultSystemLocale")
      nDefaultSLocale = oProp.Value
      '
      ' adjust available system locale list.
      '
      aSLocales = oAL.AvailableSLocalesFor(nLangId)
      If Not oAL.IsAvailableAsSLFor(nLangId,nDefaultSLocale) Then
         If UBound(aSLocales) > -1 Then
            nDefaultSLocale = aSLocales(0).LocID
         Else
            ' if available system locale list is ever empty for this
            ' language, we just set the default locale to be the fallback
            ' locale, and leave the empty array alone.
            nDefaultSLocale = nFallbackSLocale
         End If
      End If
      If Not oProp Is Nothing Then oProp.Value = nDefaultSLocale
   End Sub
End Class

'**************************************************************************************************************************
' EVENT HANDLERS AND RELATED SUBROUTINES
'**************************************************************************************************************************

'////////////////////////////////////////////////////////////////////////////
' cmiOnActivateInstance (virtual)
' Called from Config::cmiOnActivateInstance
'
' oOldInstance		Old Instance for upgrade, else Nothing
' Returns			True to allow activation, False to disallow
'
' This routine does:
'
' Initializes oConfigData so that the basic objects are set up in this object,
' and the avaialbe geographical location list is available for DHTML.
'
Function cmiOnActivateInstance(oOldInstance)

	' First call super
	If Not cmiSuper.cmiOnActivateInstance(Nothing) Then
	   Exit Function
	End If

   oLangOptions.Init cmiThis
	cmiOnActivateInstance = True

End Function


'////////////////////////////////////////////////////////////////////////////
' cmiOnConfigureRawHTML (virtual)
' Get uncooked (raw) HTML text, title, and component objects
'
' dwFlags			Arbitrary flags passed from Instance.Configure method
' Returns			aHTML structure containing uncooked data
Function cmiOnConfigureRawHTML(dwFlags)
   '
   ' Initialize our available locale lists
   '
   oLangOptions.InitLocaleList
   '
   ' cmiSuper just returns the raw HTML contents
   '
   cmiOnConfigureRawHTML = cmiSuper.cmiOnConfigureRawHTML(dwFlags)   
End Function

'////////////////////////////////////////////////////////////////////////////
' cmiOnEndBuild (virtual)
'
Sub cmiOnEndBuild(dwFlags)

   ' Call prototype script
   '
   cmiSuper.cmiOnEndBuild dwFlags

   '
   ' Create Geo value (only if there is at least one language support component)
   '
   Dim oProp
   oLangOptions.InitLocaleList ' do this again to make sure we have the latest config data
   If Not oLangOptions.oLS Is Nothing Then
      Set oProp = oLangOptions.oLS.GetProp(cmiThis.Configuration, "cmiLangDefaultLocation")
      If oProp Is Nothing Then Exit Sub ' should never happen
      oPL.TargetRegEdit cRegOpWrite, cRegCondAlways, cmiREG_SZ, cGeoRegKey, _
                        "Nation", CStr(oProp.Value), cmiString
   End If
End Sub
]]></SCRIPTTEXT>

        <HTMLTEXT
          src=".\language_settings.asp"
        ><![CDATA[<%asp%>
<%= ASP.Header %>
<% ASP.UserOnloadHandler = "LangSettingsOnLoad" %>
<%= ASP.PropHandlers %>

<SCRIPT LANGUAGE="VBScript"><!--
'
' Global variables
'
Dim oInst : Set oInst = window.external.instance
Dim oLOp : Set oLOp = oInst.script.oLangOptions

Sub LangSettingsOnLoad
   ' Now take care of our custome select element
   If oLOp.nDefaultLangId <> 0 Then
      cmixLoadProperties
	   cmiIntPropToSelect cmiLangDefaultUILanguage, oInst.Configuration.Properties("cmiLangDefaultUILanguage")
	   ResetSystemLocalesList
	   cmiIntPropToSelect cmiLangDefaultUserLocale, oInst.Configuration.Properties("cmiLangDefaultUserLocale")
	   cmiIntPropToSelect cmiLangDefaultInputLocale, oInst.Configuration.Properties("cmiLangDefaultInputLocale")
	   cmiIntPropToSelect cmiLangDefaultSystemLocale, oInst.Configuration.Properties("cmiLangDefaultSystemLocale")
	   cmiIntPropToSelect cmiLangDefaultLocation, oInst.Configuration.Properties("cmiLangDefaultLocation")
   End If
End Sub

Sub cmiIntPropToSelect(oElem, oProp)
	Dim oOptElem
	For Each oOptElem In oElem.options
		oOptElem.selected = (LCase(oOptElem.value) = LCase(CStr(oProp.Value)))
	Next
End Sub

Sub cmiIntSelectToProp(oElem, oProp)
	If Not cmixDoDataValidate(oElem, oProp) Then Exit Sub
	If oProp.Value <> oElem.value Then oProp.Value = CLng(oElem.value)
End Sub

Sub ResetSystemLocalesList
   Dim oSelect
   Dim aOp, i
   Dim aSLocales
   Dim nDefaultSLocale
   ' Reset available system locales
   oLOp.SetDefaultLangId CLng(cmiLangDefaultUILanguage.value)
   ' reset system locale list in the UI
   aSLocales = oLOp.aSLocales
   nDefaultSLocale = oLOp.nDefaultSLocale
   Set oSelect = window.document.all.Item("cmiLangDefaultSystemLocale")
   oSelect.Options.Length = 0
   'recreate option list for system locales
   For i = 0 To UBound(aSLocales)
      Set oOp = document.createElement("OPTION")
      oSelect.options.add oOp
      oOp.Value = CStr(aSLocales(i).LocID)
      oOp.innerText = aSLocales(i).Name
      oOp.selected = (nDefaultSLocale = aSLocales(i).LocID)
   Next
End Sub

--></SCRIPT>

<!-- Language selection has effects on the rest of the available options -->

<SCRIPT FOR="SelectLangIdHandler" EVENT="onblur" LANGUAGE="VBScript"><!--
   ' selection affects the available system locales
   ResetSystemLocalesList
--></SCRIPT>

<SCRIPT FOR="SelectLangIdHandler" EVENT="onchange" LANGUAGE="VBScript"><!--
   ' selection affects the available system locales
   ResetSystemLocalesList
--></SCRIPT>

<SCRIPT FOR="cmiLangSelectPropHandler" EVENT="onfocus" LANGUAGE="VBScript"><!--
'If oInst.Configuration.Properties.Exists(Me.id) Then
'	cmiIntPropToSelect Me, oInst.Configuration.Properties(Me.id)
'End If
--></SCRIPT>

<SCRIPT FOR="cmiLangSelectPropHandler" EVENT="onblur" LANGUAGE="VBScript"><!--
If oInst.Configuration.Properties.Exists(Me.id) Then
	cmixSelectToProp Me, oInst.Configuration.Properties(Me.id)
End If
' Also, need to go through elements and change the default selection in DHTML
cmiIntPropToSelect Me, oInst.Configuration.Properties(Me.id)
--></SCRIPT>

<!-- Initialize HTML Page -->
<% Dim oLOp : Set oLOp = ASP.Instance.Script.oLangOptions %>
<% Dim i %>
<% If oLOp.nDefaultLangId = 0 Then %>

<DIV STYLE = "MARGIN: 5; MARGIN-BOTTOM: 10; WIDTH:362">
<p class="callout"><b>Warning</b><br>
No user interface resources are available in the current configuration.
You need to add at least one language support component that contains user interface
rsources before changing regional and language options. For example, English Language Support component contains English user interface resources.
</p></DIV>
<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">User interface language:</LABEL>
<SELECT DISABLED STYLE = "WIDTH: 170; FONT: 8pt Tahoma;"><OPTION VALUE="1">(not available)</SELECT><BR></DIV>
<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Standards and formats:</LABEL>
<SELECT DISABLED STYLE = "WIDTH: 170; FONT: 8pt Tahoma;"><OPTION VALUE="1">(not available)</SELECT><BR></DIV>
<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Default input language:</LABEL>
<SELECT DISABLED STYLE = "WIDTH: 170; FONT: 8pt Tahoma;"><OPTION VALUE="1">(not available)</SELECT><BR></DIV>
<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Language for non-Unicode programs:</LABEL>
<SELECT DISABLED STYLE = "WIDTH: 170; FONT: 8pt Tahoma;"><OPTION VALUE="1">(not available)</SELECT><BR></DIV>
<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Geographical location:</LABEL>
<SELECT DISABLED STYLE = "WIDTH: 170; FONT: 8pt Tahoma;"><OPTION VALUE="1">(not available)</SELECT><BR></DIV>

<% Else %>

<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">User interface language:</LABEL>
<SELECT STYLE = "WIDTH: 170; FONT: 8pt Tahoma;" NAME="SelectLangIdHandler" SIZE="1" ID="cmiLangDefaultUILanguage">
<% For i = 0 To UBound(oLOp.aLangIds) %>
   <OPTION VALUE=<%=oLOp.aLangIds(i).Value%>
    <% If oLOp.aLangIds(i).Value = oLOp.nDefaultLangId Then %>
    Selected
    <% End If %>
   > <% = oLOp.aLangIds(i).Name %>
<% Next %>
</SELECT><BR></DIV>

<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Standards and formats:</LABEL>
<SELECT STYLE = "WIDTH: 170; FONT: 8pt Tahoma;" NAME="cmiLangSelectPropHandler" SIZE="1" ID="cmiLangDefaultUserLocale">
<% For i = 0 To UBound(oLOp.aULocales) %>
   <OPTION VALUE=<%=oLOp.aULocales(i).LocID%>
    <% If oLOp.aULocales(i).LocID = oLOp.nDefaultULocale Then %>
    Selected
    <% End If %>
    > <% = oLOp.aULocales(i).Name %>
<% Next %>
</SELECT><BR></DIV>

<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Default input language:</LABEL>
<SELECT STYLE = "WIDTH: 170; FONT: 8pt Tahoma;" NAME="cmiLangSelectPropHandler" SIZE="1" ID="cmiLangDefaultInputLocale">
<% For i = 0 To UBound(oLOp.aILocales) %>
   <OPTION VALUE=<%=oLOp.aILocales(i).LocID%> 
    <% If oLOp.aILocales(i).LocID = oLOp.nDefaultILocale Then %>
    Selected
    <% End If %>
   > <% = oLOp.aILocales(i).Name %>
<% Next %>
</SELECT><BR></DIV>

<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Language for non-Unicode programs:</LABEL>
<SELECT STYLE = "WIDTH: 170; FONT: 8pt Tahoma;" NAME="cmiLangSelectPropHandler" SIZE="1" ID="cmiLangDefaultSystemLocale">
<% For i = 0 To UBound(oLOp.aSLocales) %>
   <OPTION VALUE=<%=oLOp.aSLocales(i).LocID%> 
    <% If oLOp.aSLocales(i).LocID = oLOp.nDefaultSLocale Then %>
    Selected
    <% End If %>
   > <% = oLOp.aSLocales(i).Name %>
<% Next %>
</SELECT><BR></DIV>

<DIV STYLE = "MARGIN: 5" NOWRAP><LABEL STYLE = "WIDTH: 190; FONT: 8pt Tahoma;">Geographical location:</LABEL>
<SELECT STYLE = "WIDTH: 170; FONT: 8pt Tahoma;" NAME="cmiLangSelectPropHandler" SIZE="1" ID="cmiLangDefaultLocation">
<% For i = 0 To UBound(oLOp.aLocations) %>
   <OPTION VALUE=<%=oLOp.aLocations(i).Value%>
    <% If oLOp.aLocations(i).Value = oLOp.nDefaultLocation Then %>
    Selected
    <% End If %>
   > <% = oLOp.aLocations(i).Name %>
<% Next %>
</SELECT><BR></DIV>
<% End If %>

<%= ASP.Footer %>
]]></HTMLTEXT>

        <PROPERTIES
          Context="1"
          PlatformGUID="{00000000-0000-0000-0000-000000000000}"
        >
          <PROPERTY
            Name="cmiTestSelectInt"
            Format="Integer"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >1</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_1"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Anguilla;300</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_2"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Antarctica;301</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_3"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Aruba;302</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_4"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ascension Island;303</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_5"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ashmore and Cartier Islands;304</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_6"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bahamas;22</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_7"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Baker Island;305</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_8"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bangladesh;23</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_9"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Barbados;18</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_10"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Belarus;29</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_11"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Belgium;21</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_12"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Belize;24</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_13"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Benin;28</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_14"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bermuda;20</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_15"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bhutan;34</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_16"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bolivia;26</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_17"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bosnia and Herzegovina;25</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_18"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Botswana;19</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_19"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bouvet Island;306</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_20"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Brazil;32</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_21"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >British Indian Ocean Territory;114</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_22"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Bulgaria;35</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_23"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Burkina Faso;245</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_24"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Burundi;38</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_25"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cambodia;40</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_26"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cameroon;49</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_27"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Canada;39</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_28"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cape Verde;57</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_29"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cayman Islands;307</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_30"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Central African Republic;55</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_31"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Chad;41</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_32"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Channel Islands;308</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_33"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Chile;46</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_34"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >China;45</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_35"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Christmas Island;309</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_36"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Clipperton Island;310</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_37"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cocos (Keeling) Islands;311</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_38"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Colombia;51</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_39"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Comoros;50</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_40"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Congo;43</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_41"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Congo (DRC);44</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_42"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cook Islands;312</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_43"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Coral Sea Islands;313</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_44"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Costa Rica;54</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_45"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ivory Coast;119</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_46"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Croatia;108</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_47"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cuba;56</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_48"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Cyprus;59</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_49"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Czech Republic;75</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_50"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Denmark;61</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_51"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Diego Garcia;314</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_52"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Djibouti;62</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_53"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Dominica;63</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_54"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Dominican Republic;65</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_55"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ecuador;66</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_56"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Egypt;67</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_57"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >El Salvador;72</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_58"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Equatorial Guinea;69</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_59"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Eritrea;71</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_60"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Estonia;70</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_61"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ethiopia;73</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_62"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Falkland Islands (Islas Malvinas);315</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_63"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Faroe Islands;81</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_64"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Fiji Islands;78</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_65"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Finland;77</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_66"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >France;84</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_68"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >French Guiana;317</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_69"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >French Polynesia;318</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_70"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >French Southern and Antarctic Lands;319</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_71"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Gabon;87</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_72"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Gambia;86</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_73"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Georgia;88</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_74"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Germany;94</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_75"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ghana;89</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_76"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Gibraltar;90</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_77"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Greece;98</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_78"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Greenland;93</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_79"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Grenada;91</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_80"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guadeloupe;321</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_81"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guam;322</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_82"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guantanamo Bay;323</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_83"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guatemala;99</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_84"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guernsey;324</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_85"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guinea;100</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_86"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guinea-Bissau;196</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_87"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Guyana;101</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_88"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Haiti;103</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_89"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Heard Island and McDonald Islands;325</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_90"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Honduras;106</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_91"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Hong Kong S.A.R.;104</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_92"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Howland Island;326</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_93"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Hungary;109</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_94"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Iceland;110</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_95"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >India;113</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_96"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Indonesia;111</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_97"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Iran;116</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_98"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Iraq;121</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_99"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ireland;68</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_100"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Israel;117</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_101"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Italy;118</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_102"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Jamaica;124</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_103"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Jan Mayen;125</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_104"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Japan;122</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_105"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Jarvis Island;327</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_106"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Jersey;328</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_107"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Johnston Atoll;127</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_108"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Jordan;126</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_109"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Kazakhstan;137</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_110"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Kenya;129</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_111"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Kingman Reef;329</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_112"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Kiribati;133</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_113"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Korea;134</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_114"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Kuwait;136</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_115"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Kyrgyzstan;130</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_116"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Laos;138</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_117"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Latvia;140</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_118"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Lebanon;139</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_119"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Lesotho;146</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_120"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Liberia;142</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_121"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Libya;148</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_122"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Liechtenstein;145</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_123"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Lithuania;141</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_124"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Luxembourg;147</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_125"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Macau S.A.R.;151</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_126"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Macedonia;19618</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_127"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Madagascar;149</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_128"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Malawi;156</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_129"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Malaysia;167</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_130"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Maldives;165</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_131"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Mali;157</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_132"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Malta;163</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_133"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Man, Isle of;15126</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_134"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Marshall Islands;199</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_135"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Martinique;330</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_136"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Mauritania;162</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_137"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Mauritius;160</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_138"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Mayotte;331</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_139"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Mexico;166</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_140"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Micronesia;80</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_141"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Midway Islands;21242</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_142"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Moldova;152</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_143"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Monaco;158</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_144"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Mongolia;154</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_145"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Montserrat;332</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_146"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Morocco;159</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_147"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Mozambique;168</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_148"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Myanmar;27</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_149"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Namibia;254</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_150"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Nauru;180</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_151"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Nepal;178</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_152"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Netherlands;176</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_153"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Netherlands Antilles;333</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_154"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >New Caledonia;334</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_155"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >New Zealand;183</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_156"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Nicaragua;182</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_157"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Niger;173</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_158"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Nigeria;175</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_159"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Niue;335</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_160"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Norfolk Island;336</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_161"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >North Korea;131</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_162"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Northern Mariana Islands;337</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_163"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Norway;177</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_164"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Oman;164</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_165"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Pakistan;190</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_166"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Palau;195</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_167"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Palestinian Authority;184</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_168"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Palmyra Atoll;338</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_169"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Panama;192</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_170"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Papua New Guinea;194</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_171"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Paraguay;185</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_172"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Peru;187</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_173"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Philippines;201</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_174"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Pitcairn Islands;339</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_175"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Poland;191</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_176"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Portugal;193</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_177"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Puerto Rico;202</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_178"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Qatar;197</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_179"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Reunion;198</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_180"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Romania;200</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_181"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Rota Island;340</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_182"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Russia;203</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_183"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Rwanda;204</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_184"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Saipan;341</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_185"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Samoa;259</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_186"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >San Marino;214</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_187"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >São Tomé and Príncipe;233</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_188"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Saudi Arabia;205</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_189"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Senegal;210</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_190"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Seychelles;208</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_191"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Sierra Leone;213</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_192"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Singapore;215</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_193"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Slovakia;143</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_194"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Slovenia;212</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_195"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Solomon Islands;30</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_196"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Somalia;216</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_197"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >South Africa;209</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_198"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >South Georgia and the South Sandwich Islands;342</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_199"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Spain;217</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_200"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Sri Lanka;42</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_201"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >St. Helena;343</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_202"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >St. Kitts and Nevis;207</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_203"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >St. Lucia;218</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_204"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >St. Pierre and Miquelon;206</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_205"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >St. Vincent and the Grenadines;248</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_206"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Sudan;219</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_207"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Suriname;181</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_208"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Svalbard;220</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_209"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Swaziland;260</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_210"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Sweden;221</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_211"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Switzerland;223</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_212"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Syria;222</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_213"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Taiwan;237</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_214"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tajikistan;228</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_215"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tanzania;239</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_216"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Thailand;227</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_217"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tinian Island;346</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_218"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Togo;232</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_219"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tokelau;347</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_220"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tonga;231</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_221"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Trinidad and Tobago;225</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_222"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tristan da Cunha;348</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_223"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tunisia;234</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_224"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Turkey;235</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_225"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Turkmenistan;238</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_226"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Turks and Caicos Islands;349</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_227"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Tuvalu;236</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_228"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >U.S. Minor Outlying Islands;350</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_229"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Uganda;240</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_230"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Ukraine;241</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_231"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >United Arab Emirates;224</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_232"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >United Kingdom;242</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_233"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >United States;244</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_234"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Uruguay;246</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_235"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Uzbekistan;247</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_236"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Vanuatu;174</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_237"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Vatican City;253</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_238"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Venezuela;249</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_239"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Vietnam;251</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_240"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Virgin Islands;252</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_241"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Virgin Islands;351</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_242"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Wake Island;258</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_243"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Wallis and Futuna;352</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_244"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Yemen;261</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_245"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Yugoslavia;269</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_246"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Zambia;263</PROPERTY>

          <PROPERTY
            Name="cmiLangGeoLocation_247"
            Format="String"
            Context="1"
            PlatformGUID="{00000000-0000-0000-0000-000000000000}"
          >Zimbabwe;264</PROPERTY>
        </PROPERTIES>

        <RESOURCES
          Context="1"
          PlatformGUID="{B784E719-C196-4DDB-B358-D9254426C38D}"
        >        </RESOURCES>

        <GROUPMEMBERS
        >
          <GROUPMEMBER
            GroupVSGUID="{8180C915-788C-473C-80BB-BB6DF8FFA263}"
          ></GROUPMEMBER>

          <GROUPMEMBER
            GroupVSGUID="{6A222EC1-DABE-4FFF-9D78-99C9260C6C6F}"
          ></GROUPMEMBER>

          <GROUPMEMBER
            GroupVSGUID="{CF894FAA-B4C4-4F9E-8409-162FABDDD189}"
          ></GROUPMEMBER>

          <GROUPMEMBER
            GroupVSGUID="{E01B4103-3883-4FE8-992F-10566E7B796C}"
          ></GROUPMEMBER>
        </GROUPMEMBERS>

        <DEPENDENCIES
          Context="1"
          PlatformGUID="{B784E719-C196-4DDB-B358-D9254426C38D}"
        >
          <DEPENDENCY
            Class="Include"
            Type="AtLeastOne"
            DependOnGUID="{A1A56917-46F2-492E-A544-C4EB1B95F61E}"
            MinRevision="0"
            Disabled="False"
            Context="1"
            PlatformGUID="{B784E719-C196-4DDB-B358-D9254426C38D}"
          >
            <PROPERTIES
              Context="1"
              PlatformGUID="{00000000-0000-0000-0000-000000000000}"
            >            </PROPERTIES>

            <DISPLAYNAME>Regional and Language Options depends on Windows XP Embedded UI Languages</DISPLAYNAME>

            <DESCRIPTION></DESCRIPTION>
          </DEPENDENCY>
        </DEPENDENCIES>

        <DISPLAYNAME>Regional and Language Options</DISPLAYNAME>

        <VERSION>5.1.2600.1</VERSION>

        <DESCRIPTION>The user sets the default language and regional options for the run-time image using this component.</DESCRIPTION>

        <COPYRIGHT>Copyright © 2001 Microsoft Corporation</COPYRIGHT>

        <VENDOR>Microsoft Corporation</VENDOR>

        <OWNERS>Microsoft</OWNERS>

        <AUTHORS>Microsoft</AUTHORS>

        <DATECREATED>9/24/2001 6:56:01 PM</DATECREATED>

        <DATEREVISED>6/19/2002 5:07:43 PM</DATEREVISED>
      </COMPONENT>
    </COMPONENTS>

    <RESTYPES
      Context="1"
      PlatformGUID="{00000000-0000-0000-0000-000000000000}"
    >    </RESTYPES>
  </DCARRIER>
