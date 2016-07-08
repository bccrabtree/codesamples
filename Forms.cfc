<cfcomponent>	

<cffunction name="GetLocalTime" access="private" returntype="date">

	<cfargument type="numeric" name="userTimeZone" required="yes">
	
	<cfreturn DateAdd("h", ARGUMENTS.UserTimeZone, Now())>

</cffunction>

<cffunction name="getInstances" access="remote" returntype="query">

	<!--- nodeID corresponds to the issue type --->
	<cfargument name="ProcessID" type="numeric" required="yes">
	<cfargument name="formType" type="numeric" required="yes">
	<cfargument name="formCategory" type="numeric" required="yes">
	<cfargument name="ParentInstanceID" type="numeric" required="no" default="0">
	
	<cfif NOT ARGUMENTS.ParentInstanceID>
	
	<cfquery name="getInstances" datasource="jsaplus">
	select PK_InstanceID, InstanceName from tbl_instances where
	ProcessID_FK = <cfqueryparam value="#ARGUMENTS.ProcessID#" cfsqltype="cf_sql_integer">
	and FormType = <cfqueryparam value="#ARGUMENTS.FormType#" cfsqltype="cf_sql_integer">
	and FormCategory = <cfqueryparam value="#ARGUMENTS.FormCategory#" cfsqltype="cf_sql_integer">
	order by NodeID_FK, InstanceName
	</cfquery>
	
	<cfelse>
	
	<cfquery name="getInstances" datasource="jsaplus">
	select PK_InstanceID, InstanceName from tbl_instances where
	InstanceID_FK = <cfqueryparam value="#ARGUMENTS.ParentInstanceID#" cfsqltype="cf_sql_integer">
	order by NodeID_FK, InstanceName
	</cfquery>
	
	</cfif>
	
	<cfreturn getInstances>

</cffunction>

<cffunction name="getControlsSubInstances" access="remote" returntype="query">

	<cfargument name="InstanceID" type="numeric" required="yes">
	<cfargument name="FormCategory" type="numeric" required="yes">
	
	<cfset var getControlsSubInstances = "">

	<cftry>
	
	<cfquery name="getControlsSubInstances" datasource="jsaplus">
	select i.PK_InstanceID, i.InstanceName
	from tbl_instances i, tbl_nodes n
	where i.InstanceID_FK = <cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer">
	and i.FormCategory = <cfqueryparam value="#ARGUMENTS.FormCategory#" cfsqltype="cf_sql_integer">
	and i.NodeID_FK = n.PK_NodeID
	and n.NodeType = 3
	order by i.NodeID_FK, i.InstanceName
	</cfquery>
	
	<cfcatch>
	<cfthrow>
	</cfcatch>
	
	</cftry>
	
	<cfreturn getControlsSubInstances>

</cffunction>

<cffunction name="getPPEsSubInstances" access="remote" returntype="query">

	<cfargument name="InstanceID" type="numeric" required="yes">
	<cfargument name="FormCategory" type="numeric" required="yes">
	
	<cfset var getPPEsSubInstances = "">

	<cftry>
	
	<cfquery name="getPPEsSubInstances" datasource="jsaplus">
	select i.PK_InstanceID, i.InstanceName
	from tbl_instances i, tbl_nodes n
	where i.InstanceID_FK = <cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer">
	and i.FormCategory = <cfqueryparam value="#ARGUMENTS.FormCategory#" cfsqltype="cf_sql_integer">
	and i.NodeID_FK = n.PK_NodeID
	and n.NodeType = 2
	order by i.NodeID_FK, i.InstanceName
	</cfquery>
	
	<cfcatch>
	<cfthrow>
	</cfcatch>
	
	</cftry>	

	<cfreturn getPPEsSubInstances>

</cffunction>

<cffunction name="getAllSubInstances" access="remote" returntype="struct">

	<cfargument name="InstanceID" type="numeric" required="yes">
	<cfargument name="FormCategory" type="numeric" required="yes">

	<cfset var returnStruct = StructNew()>
	<cfset controlsSubInstances = "">
	<cfset PPEsSubInstances = "">
	
		<cfinvoke method="getControlsSubInstances" returnvariable="controlsSubInstances">
			<cfinvokeargument name="InstanceID" value="#arguments.InstanceID#">
			<cfinvokeargument name="FormCategory" value="#arguments.FormCategory#">
		</cfinvoke>
	
		<cfinvoke method="getPPEsSubInstances" returnvariable="PPEsSubInstances">
			<cfinvokeargument name="InstanceID" value="#arguments.InstanceID#">
			<cfinvokeargument name="FormCategory" value="#arguments.FormCategory#">
		</cfinvoke>
		
		<cfset returnStruct.controlsSubInstances = controlsSubInstances>
		<cfset returnStruct.PPE2SubInstances = PPEsSubInstances>
		
		<cfreturn returnStruc>
				
</cffunction>


<cffunction name="getStoredForms" access="remote" returntype="query">

	<cfargument type="numeric" name="siteID" required="yes">
	<cfargument type="numeric" name="accountID" required="yes">
	<cfargument type="boolean" name="getAllSites" required="no" default="false">
<!--- 	<cfargument type="boolean" name="getInactive" required="no" default="false"> --->	
 <cfargument type="numeric" name="FormType" required="yes">
	
	<cfset var getForms = "">
	
	<!--- get the stored forms for the user's site or all sites on the user's account, 
	and either forms for all or only active nodes, depending on the arguments passed --->
	<cfquery name="getForms" datasource="jsaplus">
	select distinct f.PK_SavedFormID, f.FormName
	from tbl_savedforms f, tbl_savedforms_fieldgroups fg<!--- <cfif NOT ARGUMENTS.getInactive>, tbl_nodestatus ns</cfif> --->
	<cfif ARGUMENTS.getAllSites>, tbl_sites s</cfif>
	where fg.SavedFormID_FK = f.PK_SavedFormID
	and fg.FormType = #ARGUMENTS.FormType#
	<cfif NOT ARGUMENTS.getAllSites>
	and f.SiteID_FK = <cfqueryparam value="#ARGUMENTS.SiteID#" cfsqltype="cf_sql_integer"> 
	<cfelse>
	and s.AccountID_FK = <cfqueryparam value="#ARGUMENTS.AccountID#" cfsqltype="cf_sql_integer">
	</cfif>
	<!--- <cfif NOT ARGUMENTS.getInactive>
	and f.nodeID_FK = ns.nodeID_FK
	and (select Status from tbl_nodestatus where nodeID_FK = f.nodeID_FK order by pk_nodestatusid desc limit 1) = 1
	</cfif> --->
	</cfquery>
	
	<cfreturn getForms>

</cffunction>

<cffunction name="getMasterForm" access="remote" returntype="struct">

<cfargument name="SiteID" type="numeric" required="yes">
<cfargument name="FormType" type="numeric" required="yes">

	<cfset var NodeInfo = StructNew()>
	
	<cftry>
	
	<cfquery name="CheckForMaster" datasource="jsaplus">
		select f.PK_SavedFormID, f.FormName
		from tbl_savedforms f, tbl_savedforms_fieldgroups fg
		where fg.SavedFormID_FK = f.PK_SavedFormID
		and f.SiteID_FK = <cfqueryparam value="#ARGUMENTS.SiteID#" cfsqltype="cf_sql_integer"> 
		and f.MasterForm = 1
		and fg.FormType = <cfqueryparam value="#ARGUMENTS.FormType#" cfsqltype="cf_sql_integer">
	</cfquery>
	
	<cfcatch>
	
	<cfset NodeInfo.message = cfcatch.message>
	<cfset NodeInfo.storedForm = "true">
	<cfset NodeInfo.data = ArrayNew(2)> 
	
	<cfreturn NodeInfo>

	</cfcatch>
	
	</cftry>
	
	<cfif CheckForMaster.recordcount>
	 	
			<cfinvoke method="getSelectedStoredForm" returnvariable="returnedForm">
				<cfinvokeargument name="FormID" value="#CheckForMaster.PK_SavedFormID#">
			</cfinvoke>
			
			<cfreturn returnedForm>
	
	</cfif>

</cffunction>

<cffunction name="getSelectedStoredForm" access="remote" returntype="struct">

	<cfargument type="numeric" name="FormID" required="yes">

	<cfset var saveForm = 0>
	<cfset var NodeInfo = StructNew()>
	<cfset var i = 0>
	<cfset var ii = 0>
	<cfset var iii = 0>
	
	<cfset NodeInfo.message = "success">
	<cfset NodeInfo.storedForm = "true">
	<cfset NodeInfo.data = ArrayNew(2)>

	<!--- first get the saved fieldgroups and fields --->
	<cfquery name="getFieldGroups" datasource="jsaplus">
	select fg.PK_SavedFieldGroupID, fg.FieldGroupLabel, fg.DisplayOrder as GroupOrder, 
	f.PK_SavedFieldID, f.FieldLabel, f.FieldType, f.DisplayOrder as FieldOrder  
	from tbl_savedforms sf, tbl_savedforms_fieldgroups fg, tbl_savedforms_fields f
	where sf.PK_SavedFormID = <cfqueryparam value="#ARGUMENTS.FormID#" cfsqltype="cf_sql_integer"> 
	and fg.SavedFormID_FK = sf.PK_SavedFormID
	and fg.PK_SavedFieldGroupID = f.SavedFieldGroupID_FK
	order by fg.DisplayOrder, f.DisplayOrder
	</cfquery>
	
	<cfset i = 1>
	<!--- loop over the field groups and fields and populate the array we will be returning to the front end --->
	<cfoutput query="getFieldGroups" group="GroupOrder">
	<cfset ii = 2>
	<!--- outer loop sets Field Group labels --->
	<!--- set FieldGroupID to 0, to signal a new field group --->
	<cfset NodeInfo.data[i][1]["FieldGroupID"] = 0>
	<cfset NodeInfo.data[i][1]["FieldGroupOrder"] = i>
	<cfset NodeInfo.data[i][1]["Label"]["Content"] = FieldGroupLabel>
	<cfset NodeInfo.data[i][1]["Label"]["Update"] = 0>
	
		<cfoutput>
		<!--- inner loop sets field labels, data, fieldtype, etc. --->
		<cfset NodeInfo.data[i][ii] = StructNew()>
		<!--- set Field ID to 0, to signal a new field --->
		<cfset NodeInfo.data[i][ii]["FieldID"] = 0>
		<!--- FieldOrder is used on the front end when users change the display order --->
		<cfset NodeInfo.data[i][ii]["FieldOrder"] = (ii - 1)>
	 	<cfset NodeInfo.data[i][ii]["Label"]["Content"] = FieldLabel>
		<!--- update flags are used on the front end to indicate if an item needs to be updated; they are always set to 0 here --->
		<cfset NodeInfo.data[i][ii]["Label"]["Update"] = 0>
	 	<cfset NodeInfo.data[i][ii]["FieldType"] = FieldType>	
		
		<!--- set either field options array, content array, or numeric stepper options array depending on the field type --->
		<!--- first do the field types with field options --->
		<cfif FieldType eq "CheckBox" OR FieldType eq "CalcCheckBox" OR FieldType eq "RadioGroup" OR FieldType eq "CalcRadioGroup" OR FieldType eq "CalcBoolean" OR FieldType eq "DropDownList"> 
	
		<!--- 
		For radio groups, checkboxes, and select lists, create an array to hold field options  
		The FieldOptions array indeces are as follows: 
		[1] FieldOptionLabel
		[2] FieldOptionStatus (0=created (off), 1=selected (on), 2=deselected (off), 3=deleted)
		[3] Update (boolean, always set here to 0)
		[4] FieldOptionID 
		--->
	
			<cfset NodeInfo.data[i][ii]["FieldOptions"] = ArrayNew(1)>
		
			<!--- first get the list of field options --->
			<cfquery name="getFieldOptions" datasource="jsaplus">
			select FieldOptionLabel, pk_savedfieldoptionid, FieldOptionValue 
			from tbl_savedforms_fieldoptions 
			where SavedFieldID_FK = <cfqueryparam value="#GetFieldGroups.PK_SavedFieldID#" cfsqltype="cf_sql_integer">
			</cfquery>
			
			<cfset iii = 1>
			<!--- then loop over the field options and add all options to the array --->
			<cfloop query="getFieldOptions">
				<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Label"] = getFieldOptions.FieldOptionLabel>
				<!--- a status of 0 means off, a status of 1 means on (selected) --->
				<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Status"] = 0>
				<!--- this is the update flag, always set to 0 initially  --->
				<!--- this does NOT indicate status, it is used on the front end to indicate an item needs to be updated --->
				<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Update"] = 0>
				<!--- id of 0 signals a new field --->
				<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["FieldOptionID"] = 0>
				
				<cfif getFieldGroups.FieldType eq "CalcCheckBox" OR getFieldGroups.FieldType eq "CalcRadioGroup" OR getFieldGroups.FieldType eq "CalcBoolean">
				
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Value"] = getFieldOptions.FieldOptionValue>

				</cfif>
				
				<cfset iii = iii + 1>
			</cfloop>
	
		<!--- for file upload data type, we need to create an array to hold files --->
		<!--- we also need to set the saveForm flag to 1 so we'll call updateNodeINfo now --->
		<cfelseif FieldType eq "FileUpload">
		
			<cfset saveForm = 1>
		
			<cfset NodeInfo.data[i][ii]["Files"] = ArrayNew(1)>
	
		<cfelseif FieldType eq "NumericStepper">
		
			<!--- get the stepper control options --->
			<cfquery name="getStepperSettings" datasource="jsaplus">
			select stepsize, min, max
			from tbl_savedforms_stepper_settings
			where SavedFieldID_FK = <cfqueryparam value="#GetFieldGroups.PK_SavedFieldID#" cfsqltype="cf_sql_integer">
			</cfquery>
			
			<cfset NodeInfo.data[i][ii]["StepperSettings"]["Min"] = getStepperSettings.Min>
			<cfset NodeInfo.data[i][ii]["StepperSettings"]["Max"] = getStepperSettings.Max>
			<cfset NodeInfo.data[i][ii]["StepperSettings"]["StepSize"] = getStepperSettings.StepSize>
			<cfset NodeInfo.data[i][ii]["StepperSettings"]["Update"] = 0>
	
		</cfif>

		<cfset NodeInfo.data[i][ii]["Data"]["Content"] = "">
		<!--- here is the update flag, always sent to the front end as 0 --->
		<cfset NodeInfo.data[i][ii]["Data"]["Update"] = 0>
		
		<!--- create an array to hold comments for the field --->
		<cfset NodeInfo.data[i][ii]["Comments"] = ArrayNew(1)>

		<!--- create an array to hold history for the field --->
		<cfset NodeInfo.data[i][ii]["History"] = ArrayNew(1)>
				
		<!--- end inner loop, over fields in each group --->
		<cfset ii = ii + 1>
		</cfoutput> 
		
	<!--- end outer loop, over field groups --->
	<cfset i = i + 1>
	</cfoutput>
	
	<cfif saveForm>
		
		
	
	</cfif>
	
	<cfreturn NodeInfo>

</cffunction>

<cffunction name="AddFieldGroup" access="remote" returntype="numeric" hint="I add a new form group record to the DB. I return either a new Form Group ID or 0 if there's an error">

<!--- NOTE: we do not track history for form groups, only form fields --->

	<cfargument type="numeric" name="NodeID" required="yes">
	<cfargument type="string" name="GroupLabel" required="yes">
	<!--- formtypes: 0 = NodeInfo, 1 = issues, 2 = control,  3 = injury, 4 = MSDS, 5 = comment, 6 = actions, 7 = audits --->
	<cfargument type="numeric" name="FormType" required="yes">
	<cfargument type="numeric" name="UserID" required="yes">
	<cfargument type="numeric" name="TimeZone" required="yes">
	<cfargument type="numeric" name="DisplayOrder" required="yes" default="1">
	<!--- when a fieldGroup is added independently (before the process updates button is clicked on the front end)
	because a fileUpload field is added, the fieldGroup is added with a status of 0. The status is then changed to 1 
	when the process updates button is clicked ---> 
	<cfargument type="numeric" name="Status" required="no" default="1">
	<cfargument type="numeric" name="InstanceID" required="no" default="0">
	
	<!--- Since Railo lacks the CF9 LOCAL scope, declare local variables with var keyword --->
	<cfset var NewFieldGroupID = "">	
	
	<cftry>	

	<!--- if the InstanceID is 0, we are adding a field group tied to a node (i.e., a process) --->
	<cfif NOT ARGUMENTS.InstanceID>
	
	<cfquery datasource="jsaplus" name="addgroup" result="NewFieldGroupID">
	insert into tbl_fieldgroups(FieldGroupLabel,NodeID_FK,DisplayOrder,FormType)
	values(<cfqueryparam value="#ARGUMENTS.GroupLabel#" cfsqltype="cf_sql_varchar">, 
	<cfqueryparam value="#ARGUMENTS.NodeID#" cfsqltype="cf_sql_integer">, 
	<cfqueryparam value="#(ARGUMENTS.DisplayOrder)#" cfsqltype="cf_sql_integer">, 
	<cfqueryparam value="#ARGUMENTS.FormType#" cfsqltype="cf_sql_integer">)
	</cfquery>
	
	<!--- otherwise, we are adding a field group tied to an instance (i.e., an instance of an issue, comment, PPE, or audit tied to a process --->
	<!--- or an instance of a control or PPE tied to an instance of an issue) --->
	<cfelse>

	<cfquery datasource="jsaplus" name="addgroup" result="NewFieldGroupID">
	insert into tbl_fieldgroups(FieldGroupLabel,InstanceID_FK,DisplayOrder,FormType)
	values(<cfqueryparam value="#ARGUMENTS.GroupLabel#" cfsqltype="cf_sql_varchar">, 
	<cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer">, 
	<cfqueryparam value="#(ARGUMENTS.DisplayOrder)#" cfsqltype="cf_sql_integer">, 
	<cfqueryparam value="#ARGUMENTS.FormType#" cfsqltype="cf_sql_integer">)
	</cfquery>

	</cfif>
	
	<cfcatch>
	<cfreturn 0>
	</cfcatch>

	</cftry>
	
	<cftry>
	
	<cfquery datasource="jsaplus" name="addgroupstatus">
	insert into tbl_fieldgroupstatus(FieldGroupID_FK, Status, UserID_FK, DateModified)
	values(<cfqueryparam value="#NewFieldGroupID.GENERATED_KEY#" cfsqltype="cf_sql_integer">, 
	<cfqueryparam value="#ARGUMENTS.Status#" cfsqltype="cf_sql_integer">, 
	<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">) 
	</cfquery>
	
	<cfcatch>
	</cfcatch>
	
	</cftry>
	
	<cfreturn NewFieldGroupID.GENERATED_KEY>
	
</cffunction>

<cffunction name="SetFieldGroupOrder" access="private" returntype="numeric" output="false" hint="I update the DisplayOrder value in the field groups table">

	<cfargument name="FieldGroupID" type="numeric" required="yes">
	<cfargument name="DisplayOrder" type="numeric" required="yes">
	
	<cftry>
	
	<cfquery name="updategroup" datasource="jsaplus">
	update tbl_fieldgroups
	set DisplayOrder = <cfqueryparam value="#ARGUMENTS.DisplayOrder#" cfsqltype="cf_sql_integer">
	where PK_FieldGroupID = <cfqueryparam value="#ARGUMENTS.FieldGroupID#" cfsqltype="cf_sql_integer">
	</cfquery>
	
	<cfcatch>
	<cfreturn 0>
	</cfcatch>
	
	</cftry>
	
	<!--- return 1 for success --->
	<cfreturn 1>
	
</cffunction>

<cffunction name="getFormInfo" access="remote" returntype="struct">

	<cfargument type="numeric" name="AccessLevel" required="yes">
	<cfargument type="numeric" name="NodeID" required="yes">
	<cfargument type="numeric" name="FormType" required="yes">	
	<cfargument type="numeric" name="InstanceID" required="no" default="0">
	<cfargument type="numeric" name="SubInstanceID" required="no" default="0">
	<cfargument type="numeric" name="GetSubInstances" required="no" default="0">
	<cfargument type="numeric" name="FormCategory" required="no" default="0">
	<cfargument type="boolean" name="HideSubInstanceHeader" required="no" default="false">
	
	<cfset var NodeInfo = StructNew()>
	<cfset var CurrentInstanceID = 0>
	<cfset var i = 0>
	<cfset var ii = 0>
	<cfset var iii = 0>
	<cfset var iv = 0>		
	<cfset var historyResult = "">
	<cfset var getSelectedTypes = "">

	<cfset NodeInfo.MESSAGE = "success">
	<cfset NodeInfo.STOREDFORM = "false">
	<cfset NodeInfo.DATA = ArrayNew(2)>
	<cfset NodeInfo.INSTANCES = ArrayNew(1)>
	<cfset NodeInfo.SUBINSTANCES = ArrayNew(1)>
	
	<cfif ARGUMENTS.GetSubInstances>
	
 		<cfinvoke method="getControlsSubInstances" returnvariable="controlsSubInstances">
			<cfinvokeargument name="InstanceID" value="#arguments.InstanceID#">
			<cfinvokeargument name="FormCategory" value="#arguments.FormCategory#">
		</cfinvoke>
	
		<cfinvoke method="getPPEsSubInstances" returnvariable="PPEsSubInstances">
			<cfinvokeargument name="InstanceID" value="#arguments.InstanceID#">
			<cfinvokeargument name="FormCategory" value="#arguments.FormCategory#">
		</cfinvoke>
		
		<cfset NodeInfo.SubInstances[1] = controlsSubInstances>
		<cfset NodeInfo.SubInstances[2] = PPEsSubInstances>

	</cfif>
	
	<!--- READ THE COMMENTS!!! Yes, you! --->
	
	<!--- NOTE: status is handled differently for the data field types with field options (radio buttons, checkboxes, select lists) --->
	<!--- then it is for textinput, etc. Don't get confused! Read the comments and look carefully at the code! --->
	
	<!--- first get the fieldgroups and fields (this query returns the IDs and labels of each, the field data is retrieved below) --->
	<!--- this query will only return groups and fields with a status of active --->
	<!--- it does this by checking the status flag of the last row for the group or field in the fieldgroupstatus or fieldstatus table --->
	<!--- since we are not tracking changes to the CONTENT of field group labels and field labels (only changes to their status), --->
	<!--- there will be only one row for each group in the fieldgroups table and only one row for each field in the fields table --->
	<cftry>
	
	<cfif ARGUMENTS.SubInstanceID>
	
		<cfset CurrentInstanceID = ARGUMENTS.SubInstanceID>
		<cfset nodeInfo.storedForm = "true">
	
	<cfelseif ARGUMENTS.InstanceID>
	
		<cfset CurrentInstanceID = ARGUMENTS.InstanceID>
		<cfset nodeInfo.storedForm = "true">
		
	</cfif>
	
	<cfquery name="getFieldGroups" datasource="jsaplus">
	select fg.PK_FieldGroupID, fg.FieldGroupLabel, fg.DisplayOrder as GroupOrder, 
	f.PK_FieldID, f.FieldLabel, f.FieldType, f.DisplayOrder as FieldOrder
 	from tbl_fieldgroups fg, tbl_fields f
	<cfif NOT CurrentInstanceID>
	where fg.NodeID_FK = <cfqueryparam value="#ARGUMENTS.NodeID#" cfsqltype="cf_sql_integer">
	<cfelse>
	where fg.InstanceID_FK = <cfqueryparam value="#CurrentInstanceID#" cfsqltype="cf_sql_integer">
	</cfif>
	and fg.FormType = <cfqueryparam value="#ARGUMENTS.FormType#" cfsqltype="cf_sql_integer">
	<!--- and fg.InstanceID_FK = <cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer"> --->
	and fg.PK_FieldGroupID = f.FieldGroupID_FK
	and (select Status from tbl_fieldgroupstatus where FieldGroupID_FK = fg.PK_FieldGroupID order by pk_fieldGroupStatusID desc limit 1) = 1
	and (select Status from tbl_fieldstatus where FieldID_FK = f.PK_FieldID order by pk_fieldStatusID desc limit 1) = 1
	<!--- NOTE NOTE NOTE: order by clause correct? delete pk_fieldgroupid? --->
	order by fg.DisplayOrder, f.DisplayOrder
	</cfquery>
	
	<cfcatch>
	<cfthrow detail="GetFieldGroups query error">
	</cfcatch>
	
	</cftry>
	
	<cfset i = 1>
	<!--- loop over the field groups and fields and populate the array we will be returning to the front end --->
	<cfoutput query="getFieldGroups" group="GroupOrder">
	<cfset ii = 2>
	<!--- outer loop sets Field Group labels --->
	<cfset NodeInfo.data[i][1]["FieldGroupID"] = PK_FieldGroupID>
	<!--- the FieldGroupOrder is used on the front end when the user changes the dipslay order --->
	<cfset NodeInfo.data[i][1]["FieldGroupOrder"] = "">
	<cfset NodeInfo.data[i][1]["Label"]["Content"] = FieldGroupLabel>
	<cfset NodeInfo.data[i][1]["Label"]["Update"] = 0>
	
		<cfoutput>
		<!--- inner loop sets field labels, data, fieldtype, etc. --->
		<cfset NodeInfo.data[i][ii] = StructNew()>
		<cfset NodeInfo.data[i][ii]["FieldID"] = PK_FieldID>
		<!--- FieldOrder is used on the front end when users change the display order --->
		<cfset NodeInfo.data[i][ii]["FieldOrder"] = "">
	 	<cfset NodeInfo.data[i][ii]["Label"]["Content"] = FieldLabel>
		<!--- update flags are used on the front end to indicate if an item needs to be updated; they are always set to 0 here --->
		<cfset NodeInfo.data[i][ii]["Label"]["Update"] = 0>
	 	<cfset NodeInfo.data[i][ii]["FieldType"] = FieldType>	
		
		<!--- set either field options array, content array, or numeric stepper options array depending on the field type --->
		<!--- first do the field types with field options --->
		<cfif FieldType eq "CheckBox" OR FieldType eq "CalcCheckBox" OR FieldType eq "RadioGroup" OR FieldType eq "CalcRadioGroup" OR FieldType eq "CalcBoolean" or FieldType eq "DropDownList"> 
	
		<!--- 
		For radio groups, checkboxes, and select lists, create an array to hold field options  
		The FieldOptions array indeces are as follows: 
		[1] FieldOptionLabel
		[2] FieldOptionStatus (0=created (off), 1=selected (on), 2=deselected (off), 3=deleted)
		[3] Update (boolean, always set here to 0)
		[4] FieldOptionID 
		--->
	
		<cfset NodeInfo.data[i][ii]["FieldOptions"] = ArrayNew(1)>
	
			<cftry>
			
			<!--- first get the list of field options with the status for each one (off [0 or 2], on [1], or deleted [3]) --->
			<!--- unlike how status is handled above, this query returns the latest status row for each field option, to report what the latest status is --->
			<cfquery name="getFieldOptions" datasource="jsaplus">
			select fo.FieldOptionLabel, fo.PK_FieldOptionID, fo.fieldoptionvalue,
				(select fos.status from tbl_fieldoptionsstatus fos
				where fos.fieldoptionid_fk = fo.PK_FieldOptionID
				order by fos.pk_fieldoptionstatusid desc
				limit 1) status
			from tbl_fieldoptions fo 
			where fo.FieldID_FK = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer">
			order by fo.PK_FieldOptionID
			</cfquery>
			
			<cfcatch>
			</cfcatch>
			</cftry>
			
				<!--- for the CheckBox and calculated CheckBox, loop over the fieldoptions and set status as indicated --->
				<cfif FieldType eq "CheckBox" OR FieldType eq "CalcCheckBox">
				
				<cfset iii = 1>
				<!--- then loop over the field options and add all options that are off or on (i.e., not deleted) --->
				<cfloop query="getFieldOptions">
					<!--- a status of 3 means it's deleted, so we won't return those to the front end --->
					<cfif getFieldOptions.Status neq 3>
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Label"] = getFieldOptions.FieldOptionLabel>
					<!--- a status of 0 means off, a status of 1 means on (selected) --->
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Status"] = getFieldOptions.Status>
					<!--- this is the update flag, always set to 0 initially  --->
					<!--- this does NOT indicate status, it is used on the front end to indicate an item needs to be updated --->
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Update"] = 0>
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Value"] = getFieldOptions.FieldOptionValue> 
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["FieldOptionID"] = getFieldOptions.PK_FieldOptionID>
					<cfset iii = iii + 1>
					</cfif>
				</cfloop>
	
				<!--- for radio group and DropDownList, we need to determine which field option correspondes to the latest-added status row --->
				<!--- this will be the field that is "on" --->
				<cfelse>
				
				<!--- <cfquery name="getStatusIDs" datasource="jsaplus">
				select fo.pk_fieldoptionid, fo.FieldOptionLabel, 
				(select fos.status from tbl_fieldoptionsstatus fos
				where fos.fieldoptionid_fk = FO.PK_FieldOptionID
				order by fos.pk_fieldoptionstatusid desc
				limit 1) status, fos.PK_FieldOptionstatusID
				from tbl_fieldoptions fo, tbl_fieldOptionsStatus fos
				where fo.FieldID_FK = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer">
				and fos.FieldOptionID_FK = fo.PK_FieldOptionID
				order by fo.pk_fieldoptionid, FOS.PK_FieldOptionStatusID 
				</cfquery> --->
				
				<cfquery name="getOnOption" dbtype="query" maxrows="1">
				select pk_fieldoptionid from getFieldOptions
				where status = 1
				<!--- order by pk_fieldoptionstatusid desc  --->
				</cfquery>
				
				<cfset iii = 1>
				<!--- then loop over the field options and add all options that are off or on (i.e., not deleted) --->
				<cfloop query="getFieldOptions">
					<!--- a status of 3 means it's deleted, so we won't return those to the front end --->
					<cfif getFieldOptions.Status neq 3>
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Label"] = getFieldOptions.FieldOptionLabel>
					<!--- a status of 0 means off, a status of 1 means on (selected) --->
						<cfif getFieldOptions.PK_FieldOptionID eq getOnOption.PK_FieldOptionID>
						<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Status"] = 1>
						<cfelse>
						<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Status"] = 0>
						</cfif>
					<!--- this is the update flag, always set to 0 initially  --->
					<!--- this does NOT indicate status, it is used on the front end to indicate an item needs to be updated --->
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Update"] = 0>
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["Value"] = getFieldOptions.FieldOptionValue>
					<cfset NodeInfo.data[i][ii]["FieldOptions"][iii]["FieldOptionID"] = getFieldOptions.PK_FieldOptionID>
					<cfset iii = iii + 1>
					</cfif>
				</cfloop>
				
				</cfif>
				
			<!--- set the data content to an empty string --->
			<!--- we need to do this for these field types, even though they don't use it, because the front end looks at the data content length --->
			<!--- to determine whether to display data in a richeditabletext component --->
			<cfset NodeInfo.data[i][ii]["Data"]["Content"] = "">
	
		<!--- for file upload data type, we need to get all files uploaded for the data field (and not subsequently deactivated) --->
		<!--- and populate an array with the filenames and extensions --->
		<cfelseif FieldType eq "FileUpload">
		
				<cfset NodeInfo.data[i][ii]["Files"] = ArrayNew(1)>
	
				<!--- NOTE on use of "FieldID_FK" and FileID_FK in this code: --->
				<!--- for cascade and instance saves, we save a FileID_FK and FieldID_FK value so we can reference --->
				<!--- the original file saved rather than saving multiple copies of the same files on the server --->
				<!--- if the front end sees a FileID_FK value for a file, it references the location of the original file --->
				<!--- using the FieldID_FK and FileID_FK values passed here --->
				
				<!--- a status of 0 means the file is deleted --->
				<cfquery name="getFiles" datasource="jsaplus" maxrows="1">
				select f.PK_FileID, f.FieldID_FK, f.FileName, f.FileExt, f.FileID_FK 
				from tbl_files f, tbl_filestatus fs
				where f.FieldID_FK = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer"> 
				and fs.FileID_FK = f.PK_FileID
				and fs.Status > 0
				</cfquery>	
				
				<cfset iii = 1>
				<cfloop query="getFiles">
				<cfset NodeInfo.data[i][ii]["Files"][iii]["FileID"] = getFiles.PK_FileID>
				<cfset NodeInfo.data[i][ii]["Files"][iii]["FileID_FK"] = getFiles.FileID_FK>
				<cfif getFiles.FileID_FK neq 0>
					<cfquery name="getParentFieldID" datasource="jsaplus">
						select FieldID_FK from tbl_files 
						where PK_FileID = <cfqueryparam value="#getFiles.FileID_FK#" cfsqltype="cf_sql_integer">
					</cfquery>
					<cfset NodeInfo.data[i][ii]["Files"][iii]["FieldID_FK"] = getParentFieldID.FieldID_FK>
				<cfelse>
					<cfset NodeInfo.data[i][ii]["Files"][iii]["FieldID_FK"] = 0>
				</cfif>
				<cfset NodeInfo.data[i][ii]["Files"][iii]["FileName"] = getFiles.FileName>
				<cfset NodeInfo.data[i][ii]["Files"][iii]["FileExt"] = getFiles.FileExt>
				<cfset NodeInfo.data[i][ii]["Files"][iii]["Update"] = 0>
				<cfset iii = iii + 1>
				</cfloop>
		
				<cfset NodeInfo.data[i][ii]["Data"]["Content"] = "">
	
		<cfelse>
		
			<!--- numericstepper data is stored as text so it can be a decimal or nondecimal number --->
			<!--- also the change history works the same as it does for the textinput field types --->
			<cfif FieldType eq "TextInput" or FieldType eq "NumericStepper">
	
			<!--- get the latest row corresponding to the field ID --->
			<cfquery name="getFieldData" datasource="jsaplus">
			SELECT PK_FieldDataID, Data FROM tbl_fielddata_shorttext
			WHERE fieldid_fk = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer"> 
			ORDER BY PK_FieldDataID DESC
			Limit 1
			</cfquery>
			
				<cfif FieldType eq "NumericStepper">
		
					<!--- get the stepper control options --->
					<cfquery name="getStepperSettings" datasource="jsaplus">
					select stepsize, min, max
					from tbl_stepper_settings
					where FieldID_FK = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer"> 
					</cfquery>
					
					<cfset NodeInfo.data[i][ii]["StepperSettings"]["Min"] = getStepperSettings.Min>
					<cfset NodeInfo.data[i][ii]["StepperSettings"]["Max"] = getStepperSettings.Max>
					<cfset NodeInfo.data[i][ii]["StepperSettings"]["StepSize"] = getStepperSettings.StepSize>
					<cfset NodeInfo.data[i][ii]["StepperSettings"]["Update"] = 0>
	
				</cfif>
				
			<cfelseif FieldType eq "TextArea">	
	
			<!--- get the latest row corresponding to the field ID --->
			<cfquery name="getFieldData" datasource="jsaplus">
			SELECT PK_FieldDataID, Data FROM tbl_fielddata_longtext
			WHERE fieldid_fk = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer">
			ORDER BY PK_FieldDataID DESC
			Limit 1
			</cfquery>
			
			<cfelseif FieldType eq "DateField">	
	
			<!--- get the latest row corresponding to the field ID --->
			<cfquery name="getFieldData" datasource="jsaplus">
			SELECT PK_FieldDataID, Data FROM tbl_fielddata_date
			WHERE fieldid_fk = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer">
			ORDER BY PK_FieldDataID DESC
			Limit 1
			</cfquery>
	
			</cfif>
	
			<cfif getFieldData.recordcount>
			<cfset NodeInfo.data[i][ii]["Data"]["Content"] = GetFieldData.Data>
			<cfset NodeInfo.data[i][ii]["Data"]["ID"] = GetFieldData.PK_FieldDataID>
			<cfelse>
			<cfset NodeInfo.data[i][ii]["Data"]["Content"] = "">
			</cfif>
		
		</cfif>
		
		<!--- create an array to hold comments for the field --->
		<cfset NodeInfo.data[i][ii]["Comments"] = ArrayNew(1)>
		<!--- get the comments for the field and add them to the array --->
		<cfquery name="getFieldComments" datasource="jsaplus">
		select c.*, u.FirstName, u.LastName from tbl_field_comments c, tbl_users u
		where c.FieldID_FK = <cfqueryparam value="#GetFieldGroups.PK_FieldID#" cfsqltype="cf_sql_integer">
		and c.UserID_FK = u.PK_UserID
		</cfquery>
		
		<cfset counter = 0>
		<cfloop query="getFieldComments">
		<cfset counter = counter + 1>
		<cfset NodeInfo.data[i][ii]["Comments"][counter]["Content"] = "#getFieldComments.FieldComment#">
		<cfset NodeInfo.data[i][ii]["Comments"][counter]["Name"] = "#getFieldComments.FirstName# #getFieldComments.LastName#">
		<cfset NodeInfo.data[i][ii]["Comments"][counter]["Date"] = "#DateFormat(getFieldComments.DateModified, 'MM-DD-YYYY HH:MM')#">
		<cfset NodeInfo.data[i][ii]["Comments"][counter]["Update"] = 0>
		</cfloop>
		

		<!--- create an array to hold history for the field --->
		<cfset NodeInfo.data[i][ii]["History"] = ArrayNew(1)>

		<!---get history for the field and add to the array--->
		<cfinvoke component="History" method="getHistory" returnVariable="historyResult">
	
		<cfinvokeargument name="FieldID" value="#GetFieldGroups.PK_FieldID#">
		<cfinvokeargument name="FieldType" value="#GetFieldGroups.FieldType#">
		
		</cfinvoke>
	
		<cfset counter = 0>
		<cfloop query="historyResult.data">
		<cfset counter = counter + 1>
		<!--- <cfset NodeInfo.data[i][ii]["History"][#getFieldGroups.PK_FieldID#] = "#historyresult.data#"> --->
		<cfset NodeInfo.data[i][ii]["History"][counter]["Data"] = "#historyresult.data.Data#">		
		<cfset NodeInfo.data[i][ii]["History"][counter]["Status"] = "#historyresult.data.Status#">		
		<cfset NodeInfo.data[i][ii]["History"][counter]["Date"] = "#historyresult.data.DateModified#">		
		<cfset NodeInfo.data[i][ii]["History"][counter]["Name"] = "#historyresult.data.FirstName# #historyresult.data.LastName#">		
		</cfloop>
		
		<!--- here is the update flag, always sent to the front end as 0 --->
		<cfset NodeInfo.data[i][ii]["Data"]["Update"] = 0>
				
		<!--- end inner loop, over fields in each group --->
		<cfset ii = ii + 1>
		</cfoutput> 
		
	<!--- end outer loop, over field groups --->
	<cfset i = i + 1>
	</cfoutput>
	
	<cfif NOT ArrayLen(NodeInfo.data) AND ARGUMENTS.AccessLevel eq 3>
	
		
	
	
	</cfif>
	
	<cfif ARGUMENTS.HideSubInstanceHeader>
	<cfset nodeInfo.message = "hideSubInstanceHeader">
	
	</cfif>
	
	<!--- <cfset newindexnumber = arrayLen(NodeInfo.data) + 1>
	<cfset NodeInfo.data[newindexnumber][1]["Label"]["Content"] = "Testing New Group">
	<cfset NodeInfo.data[newindexnumber][1]["Label"]["Update"] = 0>
	<cfset NodeInfo.data[newindexnumber][1]["FieldGroupID"] = 0>  --->

	<cfreturn NodeInfo>

</cffunction>


<cffunction name="addFieldOption" access="private" returntype="numeric" output="false" hint="I add a field option to a checkbox, radio group, or select list field">

	<cfargument name="FieldID" type="numeric" required="yes">
	<cfargument name="Content" type="string" required="yes">
	<cfargument name="UserID" type="numeric" required="yes">
	<cfargument name="TimeZone" type="numeric" required="yes">
	<cfargument name="Value" type="numeric" required="no" default="0">
	
	<cfset var NewFieldOption = "">

	<cftry>
		
		<cfquery datasource="jsaplus" name="addfieldoptionquery" result="NewFieldOption">
		insert into tbl_fieldoptions(FieldID_FK, FieldOptionLabel, FieldOptionValue)
		values(<cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">, 
		<cfqueryparam value="#ARGUMENTS.Content#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#ARGUMENTS.Value#" cfsqltype="cf_sql_integer">)
		</cfquery>
							
	<cfcatch>
		<cfreturn 0>
	</cfcatch>
										
	</cftry>
										
	<cftry>
	
		<cfquery name="addfieldoptionstatus" datasource="jsaplus">
		insert into tbl_fieldoptionsstatus(FieldOptionID_FK, Status, UserID_FK, DateModified)
		values(<cfqueryparam value="#NewFieldOption.GENERATED_KEY#" cfsqltype="cf_sql_integer">, 
		0, 
		<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">, 
		<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">)
		</cfquery>
	
		<cfcatch>
			<cfreturn 0>
		</cfcatch>
	
	</cftry>
	
	<cfreturn NewFieldOption.GENERATED_KEY>

</cffunction> 

 <cffunction name="getForm" access="remote" returntype="struct" output="true">

	<cfargument type="numeric" name="NodeID" required="yes">

	<cfset var result = StructNew()>
	<cfset var GetFormFields = StructNew()>
	
	<cftry>
	
	<cfinvoke method="getFormGroups" returnVariable="FormGroups" NodeID="#ARGUMENTS.NodeID#">
	
	<cfset result.GROUPS = FormGroups.Data>
	
	<cfset counter = 0>

	<cfoutput query="result.Groups">
	
	<cfquery name="GetFormFields" datasource="jsaplus">
	select * from tbl_fields
	where fieldgroupid_fk = <cfqueryparam value="#pk_fieldgroupid#" cfsqltype="cf_sql_integer">	
	order by displayorder
	</cfquery>
	
<!--- 
	<cfset result.Fields[#pk_fieldgroupid#] = GetFormFields>
 --->
	<cfset result.FIELDS[counter] = GetFormFields>
	
	<cfset counter = counter + 1>	
	</cfoutput>
	
	<cfcatch>
		
	<cfset result.message = "error">	
	
	</cfcatch>
	
	</cftry>
	
	<cfset result.message = "success">
	
	<cfreturn result> 

</cffunction> 

<cffunction name="getFormGroups" access="remote" returntype="struct">

	<cfargument name="NodeID" type="numeric" required="yes">

	<cfset var result = StructNew()>
	<cfset var getFormGroup = "">
	<cftry>
	
	<cfquery name="getFormGroups" datasource="jsaplus">
	select PK_FieldGroupID, FieldGroupName, DisplayOrder
	from tbl_fieldgroups 
	where NodeID_FK = <cfqueryparam value="#ARGUMENTS.NodeID#" cfsqltype="cf_sql_integer">
	order by DisplayOrder
	</cfquery>
	
	<cfcatch>
	<cfset result.message = "error">
	</cfcatch>
	
	</cftry>	
	
	<cfset result.message = "success">
	<cfset result.data = getFormGroups>	
	
	<cfreturn result>

</cffunction>

<cffunction name="addFormItem" access="remote" returntype="string">

	<cfargument type="struct" name="NewFormItem" required="yes">

	<cfset var DisplayOrder = 0>
	<cfset var getDisplayOrder = "">
	<cfset var nodetable = "">
	
	<cfquery name="getDisplayOrder" datasource="jsaplus">
	select MAX(DisplayOrder) as DisplayOrder from tbl_nodes
	where ParentID = <cfqueryparam value="#getparentID.ParentID#" cfsqltype="cf_sql_integer">
	</cfquery>
	
	<cfset DisplayOrder = getDisplayOrder.DisplayOrder + 1>
	
	<cfquery name="nodetable" datasource="jsaplus">
	insert into tbl_nodes(ParentID,NodeName,DisplayOrder,LicenseID_FK)
	values(<cfqueryparam value="#Arguments.NewNode.NodeID#" cfsqltype="cf_sql_integer">, 
	<cfqueryparam value="#ARGUMENTS.NewNode.NodeDescription#" cfsqltype="cf_sql_varchar">, 
	<cfqueryparam value="#DisplayOrder#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#ARGUMENTS.NewNode.LicenseID#" cfsqltype="cf_sql_integer">)
	</cfquery>

	<cfreturn "success">
	
</cffunction>

<cffunction name="getFormFields" access="remote" returntype="query">

	<cfargument name="FieldGroupID" type="numeric" required="yes">
	
	<CFSET getFormFields = "">
	
	<cfquery name="GetFormFields" datasource="jsaplus">
	select * from tbl_fields
	where fieldgroupid_fk = #ARGUMENTS.fieldgroupid#	
	</cfquery>
	
	<cfreturn getFormFields>

</cffunction>
 
<cffunction name="addFormField" access="remote" returntype="numeric">

	<cfargument type="struct" name="NewFormField" required="yes">
	<cfargument type="numeric" name="FieldGroupID" required="yes">
	<cfargument type="numeric" name="UserID" required="yes">	
	<cfargument type="numeric" name="TimeZone" required="yes">	
	<cfargument type="numeric" name="DisplayOrder" required="yes">	
	<cfargument type="numeric" name="Status" required="no" default="1">
	
	<!--- set local vars for Railo compatibility --->
	<cfset var i = 0>
	<cfset var NewField = "">
	<cfset var NewFieldOption = "">
	
	<cftry>	

	<!--- add the new field to the fields table --->
	<cfquery name="addfield" datasource="jsaplus" result="NewField">
	insert into tbl_fields(FieldLabel,FieldGroupID_FK,FieldType,DisplayOrder)
	values(<cfqueryparam value="#ARGUMENTS.NewFormField.Label['Content']#" cfsqltype="cf_sql_varchar">, 
	<cfqueryparam value="#ARGUMENTS.FieldGroupID#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#ARGUMENTS.NewFormField.FieldType#" cfsqltype="cf_sql_varchar">,
	<cfqueryparam value="#ARGUMENTS.DisplayOrder#" cfsqltype="cf_sql_integer">)
	</cfquery>

	<cfcatch>
	<!--- return 0 for errors --->
	<cfreturn 0>
	</cfcatch>

	</cftry>
	
	<cftry>
	
	<!--- set field status and record user ID --->
	<!--- status of 0 will be set when this function is called directly from the front end (when adding a fileupload field) --->
	<cfquery name="addfieldstatus" datasource="jsaplus">
	insert into tbl_fieldstatus(FieldID_FK, Status, UserID_FK, DateModified)
	values(<cfqueryparam value="#NewField.GENERATED_KEY#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#ARGUMENTS.Status#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">)
	</cfquery>
	
	<cfcatch>
	<cfreturn 0>
	</cfcatch>
	
	</cftry>

	<cfreturn NewField.GENERATED_KEY>
	
</cffunction>


<cffunction name="deleteField" access="private" returntype="numeric">

	<cfargument type="numeric" name="FieldID" required="yes">
	<cfargument type="numeric" name="UserID" required="yes">
	<cfargument type="numeric" name="TimeZone" required="yes">

	<cftry>	
	
	<cfquery name="addfieldstatus" datasource="jsaplus">
	insert into tbl_fieldstatus(FieldID_FK, Status, UserID_FK, DateModified)
	values(<cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">,
	0,
	<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">)
	</cfquery>

	<cfcatch>
	<!--- return 0 for error --->
	<cfreturn 0>
	</cfcatch>

	</cftry>

	<!--- return 1 for success --->
	<cfreturn 1>
	
</cffunction>

<cffunction name="deleteFieldGroup" access="private" returntype="numeric">

	<cfargument type="numeric" name="FieldGroupID" required="yes">
	<cfargument type="numeric" name="UserID" required="yes">
	<cfargument type="numeric" name="TimeZone" required="yes">

	<cfset var getFieldIDs = "">
	
	<cftry>
	
	<!--- get all the field IDs associated with the field group we're deleting --->
	<cfquery name="getFieldIDs" datasource="jsaplus">
	select PK_FieldID from tbl_fields where FieldGroupID_FK = <cfqueryparam value="#ARGUMENTS.FieldGroupID#" cfsqltype="cf_sql_integer">
	</cfquery>
	
	<cfcatch>
	<!--- return 0 for errors --->
	<cfreturn 0>
	</cfcatch>
	
	</cftry>
	
	<!--- add a record to the field status table for each deleted field --->
	<cfif getFieldIDs.recordcount>

		<cfoutput query="getFieldIds">

			<cftry>
			
			<cfquery name="addfieldstatus" datasource="jsaplus">
			insert into tbl_fieldstatus(FieldID_FK, Status, UserID_FK, DateModified)
			values(<cfqueryparam value="#getFieldIDs.PK_FieldID#" cfsqltype="cf_sql_integer">,
			0,
			<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
			<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">)
			</cfquery>

			<cfcatch>
			<cfreturn 0>
			</cfcatch>
			
			</cftry>

		</cfoutput>

	</cfif>
	
	<!--- add a record to the field group status table for the deleted group --->
	
	<cftry>

	<cfquery name="addgroupstatus" datasource="jsaplus">
	insert into tbl_fieldgroupstatus(FieldGroupID_FK, Status, UserID_FK, DateModified)
	values(<cfqueryparam value="#ARGUMENTS.FieldGroupID#" cfsqltype="cf_sql_integer">,
	0,
	<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
	<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">)
	</cfquery>

	<cfcatch>
	<cfreturn 0>
	</cfcatch>

	</cftry>

	<!--- return 1 for success --->
	<cfreturn 1>
	
</cffunction>

<cffunction name="getFieldHistory" access="private" returntype="struct">

	<cfargument type="numeric" name="FieldID" required="yes">
	<cfargument type="string" name="FieldType" required="yes">
	
	<cfset var response = StructNew()>
	<cfset var GetHistory = "">
	
	<cfif ARGUMENTS.FieldType eq "TextInput" or ARGUMENTS.FieldType eq "NumericStepper">
		
			<cftry>
			
			<cfquery name="GetHistory" datasource="jsaplus">
			select d.Data, DATE_FORMAT(d.DateModified, '%m/%d/%Y %r') as DateModified, u.LastName, u.FirstName, "Data Modified" as Status
			from tbl_fielddata_shorttext d, tbl_users u
			where d.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
			and d.UserID_FK = u.PK_UserID
			UNION
			select "" as Data, fs.DateModified, u.LastName, u.FirstName, IF(fs.Status = 1, 'Field Added', 'Field Deleted') as Status
			from tbl_fieldstatus fs, tbl_users u
			where fs.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
			and fs.UserID_FK = u.PK_UserID
			order by datemodified desc
			</cfquery>
			
			<cfcatch>
			<cfset response.message = "error">
			<cfreturn response>
			</cfcatch>
			
			</cftry>

	<cfelseif ARGUMENTS.FieldType eq "TextArea">
		
			<cftry>

			<cfquery name="getHistory" datasource="jsaplus">
			select d.Data, DATE_FORMAT(d.DateModified, '%m/%d/%Y %r') as DateModified, u.LastName, u.FirstName, "Data Modified" as Status
			from tbl_fielddata_longtext d, tbl_users u
			where d.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
			and d.UserID_FK = u.PK_UserID
			UNION
			select "" as Data, fs.DateModified, u.LastName, u.FirstName, IF(fs.Status = 1, 'Field Added', 'Field Deleted') as Status
			from tbl_fieldstatus fs, tbl_users u
			where fs.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
			and fs.UserID_FK = u.PK_UserID
			order by datemodified desc
			</cfquery>

			<cfcatch>
			<cfset response.message = "error">
			<cfreturn response>
			</cfcatch>
			
			</cftry>

	<cfelseif ARGUMENTS.FieldType eq "FileUpload">
		
			<cftry>

			<cfquery name="getHistory" datasource="jsaplus">
			select CONCAT_WS(".", f.FileName, f.FileExt) as Data, fs.UserID_FK, DATE_FORMAT(fs.DateModified, '%m/%d/%Y %r') as DateModified, IF(fs.Status = 1, 'Added', 'Deleted') as Status, u.LastName, u.FirstName
			from tbl_files f, tbl_filestatus fs, tbl_users u
			where f.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
			and fs.FileID_FK = f.PK_FileID
			and fs.UserID_FK = u.PK_UserID
			order by PK_FileStatusID desc
			</cfquery>
			
			<cfcatch>
			<cfset response.message = "error">
			<cfreturn response>
			</cfcatch>
			
			</cftry>

	<cfelseif ARGUMENTS.FieldType eq "DateField">
		
			<cftry>		

			<cfquery name="getHistory" datasource="jsaplus">
			select d.Data, DATE_FORMAT(d.DateModified, '%m/%d/%Y %r') as DateModified, u.LastName, u.FirstName, "Data Modified" as Status
			from tbl_fielddata_date d, tbl_users u
			where d.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
			and d.UserID_FK = u.PK_UserID
			UNION
			select "" as Data, fs.DateModified, u.LastName, u.FirstName, IF(fs.Status = 1, 'Field Added', 'Field Deleted') as Status
			from tbl_fieldstatus fs, tbl_users u
			where fs.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
			and fs.UserID_FK = u.PK_UserID
			order by datemodified desc
			</cfquery>

			<cfcatch>
			<cfset response.message = "error">
			<cfreturn response>
			</cfcatch>
			
			</cftry>

	<cfelseif ARGUMENTS.FieldType eq "Tree">
	<!--- add later --->
	
	<!--- this condition covers check boxes, radio groups, and DropDownListes --->
	<cfelse>
		
		<cftry>

		<cfquery name="getHistory" datasource="jsaplus">
		select fo.FieldOptionLabel as Data, CASE s.Status WHEN 0 then 'Created' WHEN 1 then 'Selected' WHEN 2 then 'Deselected' WHEN 3 then 'Deleted' END as Status, DATE_FORMAT(s.DateModified, '%m/%d/%Y %r') as DateModified, u.LastName, u.FirstName
		from tbl_fieldoptions fo, tbl_fieldoptionsstatus s, tbl_users u
		where fo.FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
		and s.FieldOptionID_FK = PK_FieldOptionID
		and s.UserID_FK = u.PK_UserID
		</cfquery>
		
		<cfcatch>
		<cfset response.message = "error">
		<cfreturn response>
		</cfcatch>
			
		</cftry>

	</cfif>	
	
	<cfset response.message = "success">
	<cfset response.data = getHistory>
	<cfreturn response>

</cffunction>

<cffunction name="getFileID" access="remote" returntype="struct">

	<cfargument type="numeric" name="FieldID" required="yes">
	<cfargument type="numeric" name="Recordcount" required="yes">
	
	<cfset var response = structNew()>
	
	<cftry>
	
	<cfquery name="getFileInfo" datasource="jsaplus">
	select * from tbl_files where FieldID_FK = <cfqueryparam value="#ARGUMENTS.FieldID#" cfsqltype="cf_sql_integer">
	order by PK_FileID desc 
	</cfquery>
	
	<cfcatch>
	<cfset response.message = "error">
	<cfreturn response>
	</cfcatch>
	
	</cftry>
	
	<cfif getFileInfo.recordcount gt arguments.recordcount>

	<cfset response.message = "succcess">
	<cfset response.FileID = getFileInfo.PK_FileID>
	<cfset response.FileName = getFileInfo.FileName>
	<cfset response.FileExt = getFileInfo.FileExt>
	
	<cfreturn response>
	</cfif>
	
	
	<cfset response.message = "timeout">
	
	<cfreturn response>	
	
</cffunction>

<!--- <cffunction name="addInstance" access="remote" returntype="numeric" hint="I add a record to the instances table and return the new InstanceID.">


</cffunction>
 --->

<!--- end of UpdateProcess function --->
<cffunction name="updateSelectedTypes" access="remote" returntype="void">

<cfargument name="InstanceID" type="numeric" required="yes">
<cfargument name="UserID" type="numeric" required="yes">
<cfargument name="TimeZone" type="numeric" required="yes">
<cfargument name="SelectedTypes" type="array" required="yes">

	<!--- get the last set of selected types --->
	<cfquery name="getSelectedTypes" datasource="jsaplus">
	select PK_SelectedTypeID, TypeID_FK, Status 
	from tbl_selected_types 
	where InstanceID_FK = <cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer">
	</cfquery>
	
	<cfloop query="getSelectedTypes">
	
		<cfif NOT ArrayFind(ARGUMENTS.nodeInfo[i][ii]['SelectedTypes'], getSelectedTypes.TypeID_FK) AND getSelectedTypes.Status eq 1>
			<cfquery name="updateselectedtypes" datasource="jsaplus">
			update tbl_selected_types
			set status = 0,
			UserID_FK = <cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
			DateModified = <cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">
		 	where PK_SelectedTypeID = <cfqueryparam value="#getSelectedTypes.PK_SelectedTypeID#">
			</cfquery>
			
		</cfif> 
		
	</cfloop>
	
		<cfquery name="getActiveSelectedTypes" dbtype="query">
		select * from getSelectedTypes
		where status = 1
		</cfquery>
		
		<cfset vi = 0>
		<!--- loop over the array of selected types and add to or update tbl_selected_types as appropriate --->
		<cfloop from="1" to="#ArrayLen(SelectedTypes)#" index="vi">
			
			<cfif NOT Find(vi, ValueList(getActiveSelectedTypes.TypeID_FK))>
			
			<cfquery name="addselectedtype" datasource="jsaplus">
			insert into tbl_selected_types(InstanceID_FK, TypeID_FK, UserID_FK, DateModified, Status)
			values(<cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer">,
			<cfqueryparam value="#vi#" cfsqltype="cf_sql_integer">,								
			<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
			<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">,
			<cfqueryparam value="1" cfsqltype="cf_sql_integer">)
			</cfquery>
			</cfif>
		
		</cfloop>  

</cffunction>


<!--- this function JUST adds records to the instances and instance status tables. UpdateNodeInfo handles all the details of each instance, just as it does for process info. This function returns just a single instance ID, for a top-level instance just added. It is set up as a separate function rather than being integrated into UpdateNodeInfo because when the user uses the Control or PPE multiadd function, this function is called directly from the front end, bypassing UpdateNodeInfo, since the only thing that is required in that case is to save "empty" second-level instances. --->
<cffunction name="UpdateInstances" access="remote" returntype="struct" hint="I add and remove issue, control, comment, audit, and PPE instance records.">

	<!--- the process ID refers to the selected process (of course) --->
	<cfargument name="ProcessID" type="numeric" required="yes">
	<!--- if an InstanceID of 0 is passed in, then we are adding a top-level instance --->
	<!--- otherwise, we are adding one or more second-level (control or PPE) instances tied to an issue instance --->
	<cfargument name="InstanceID" type="numeric" required="yes">
	<!--- this indicates the form (instance) category (safety, quality, LEAN, sustainability, ergonomics) --->
	<cfargument name="FormCategory" type="numeric" required="yes">
	<!--- note that the form type (issue, control, PPE, comment, audit) gets stored with the fieldgroups, not with instances --->
	<cfargument name="FormType" type="numeric" required="yes">
	<!--- the selected Node(s) correspond to the instance(s) issue, control, or ppe type(s) --->
	<!--- this array will contain just one element when we are adding a top-level instance or just one second-level instance, and ---> 
	<!--- it will contain multiple elements when we are saving multiple second-level instances ---> 	
	<cfargument name="SelectedNodes" type="array" required="yes">
	<cfargument name="UserID" type="numeric" required="yes">
	<cfargument name="TimeZone" type="numeric" required="yes">
	
	<cfset var InstanceName = "">
	<cfset var i = "">
	<cfset var InstanceCount = 0>
	<cfset var NewInstance = 0>
	<cfset var response = StructNew()>
	<cfset response.message = "success">
	<cfset response.InstanceID = 0>
	<cfset response.InstanceName = "">
	
	<!--- if the selectedNodes array is empty, we are deleting an existing top-level instance --->
	<!--- (we don't actually delete it, we add a record with status o to the status table) --->
	<cfif NOT ArrayLen(ARGUMENTS.SelectedNodes)>

		<cftry>
		
		<cfquery name="DeleteInstance" datasource="jsaplus">
		insert into tbl_instancestatus(InstanceID_FK, Status, UserID_FK, DateModified)
		values(<cfqueryparam value="#NewInstance.GENERATED_KEY#" cfsqltype="cf_sql_integer">, 
		<cfqueryparam value="0" cfsqltype="cf_sql_integer">, 
		<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
		<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">) 
		</cfquery>

		<cfcatch>
		<cfset response.message = "DeleteInstanceError">
		<cfreturn response>
		</cfcatch>
		
		</cftry>	
	
	<!--- if the selectedNodes array is not empty, we are adding one or more instances --->
	<cfelse>

		<!--- loop over the selected nodes. When adding a top-level instance, this array will always have a length of just 1. --->
		<cfloop array="#ARGUMENTS.SelectedNodes#" index="i">
		
			<!--- we need a lock here because we are naming instances sequentially --->
			<cflock type="exclusive" name="AddInstance#ARGUMENTS.ProcessID#" timeout="30">
	
			<cftry>
		
			<!--- first we need a count of all active instances for the ProcessID or InstanceID passed from the front end or UpdateNodeInfo --->
			<!--- we will number duplicate instances sequentially, so we begin by checking the number of existing --->
			<!--- instances for the selected Process or Instance and category (safety, quality, lean, sustainability, or ergonomics) --->
			<cfquery name="getInstanceCount" datasource="jsaplus">
			select count(*) as InstanceCount from tbl_instances i
			<!--- if instance ID passed in is 0, we are adding a new top-level instance tied to a process node --->
			<cfif NOT Arguments.InstanceID>
			where i.ProcessID_FK = <cfqueryparam value="#ARGUMENTS.ProcessID#" cfsqltype="cf_sql_integer">
			<!--- otherwise, we are adding a second-level instance tied to another (issue) instance --->
			<cfelse>
			where i.InstanceID_FK = <cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer">
			</cfif>
			and i.NodeID_FK = #i#
			and i. FormCategory = <cfqueryparam value="#ARGUMENTS.FormCategory#" cfsqltype="cf_sql_varchar">
			and (select Status from tbl_instancestatus where InstanceID_FK = i.PK_InstanceID order by pk_InstanceStatusID desc limit 1) = 1
			</cfquery>
	
			<cfcatch>
			<cfthrow detail="#cfcatch.message#">
			</cfcatch>
			
			</cftry>
	
			<cfset InstanceCount = getInstanceCount.InstanceCount>
	
			<!--- now we can create the instance name. --->
			<cftry>
				
			<!--- First, get the nodename of the selected issue, control, comment, or audit type) --->			
			<cfquery name="getNodeName" datasource="jsaplus">
			select NodeName from tbl_nodes where PK_NodeID = <cfqueryparam value="#i#" cfsqltype="cf_sql_integer">
			</cfquery>
				
			<cfcatch>
			<cfthrow detail="#cfcatch.message#">
			</cfcatch>
			
			</cftry>
		
			<cfif getNodeName.recordcount>
		
				<cfset InstanceCount = InstanceCount + 1>
				<cfif InstanceCount lt 10>
					<cfset InstanceCount = "0#InstanceCount#">
				</cfif>
				<cfset InstanceName = "#getNodeName.NodeName# #instancecount#">
				
				<cftry>
			
				<!--- if we are adding a top-level instance, we add an instance tied to a ProcessID and a NodeID --->
				<cfif NOT ARGUMENTS.InstanceID>
				
					<cfquery name="addInstance" datasource="jsaplus" result="NewInstance">
					insert into tbl_instances(InstanceName, ProcessID_FK, NodeID_FK, FormType, FormCategory)
					values(<cfqueryparam value="#InstanceName#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#ARGUMENTS.ProcessID#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#i#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#ARGUMENTS.FormType#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#ARGUMENTS.FormCategory#" cfsqltype="cf_sql_integer">)
					</cfquery>
				
				<!--- if we are adding a second-level instance, we add an instance tied to another instance ID and a NodeID --->
				<cfelse>
				
					<cfquery name="addInstance" datasource="jsaplus" result="NewInstance">
					insert into tbl_instances(InstanceName, InstanceID_FK, NodeID_FK, FormCategory)
					values(<cfqueryparam value="#InstanceName#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#ARGUMENTS.InstanceID#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#i#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#ARGUMENTS.FormCategory#" cfsqltype="cf_sql_integer">)
					</cfquery>
				
				</cfif>
	
				<cfcatch>
				<cfthrow detail="#cfcatch.message#">
				</cfcatch>
				
				</cftry>
				
				<cftry>
				
				<cfquery name="AddInstanceStatus" datasource="jsaplus">
				insert into tbl_instancestatus(InstanceID_FK, Status, UserID_FK, DateModified)
				values(<cfqueryparam value="#NewInstance.GENERATED_KEY#" cfsqltype="cf_sql_integer">, 
				<cfqueryparam value="1" cfsqltype="cf_sql_integer">, 
				<cfqueryparam value="#ARGUMENTS.UserID#" cfsqltype="cf_sql_integer">,
				<cfqueryparam value="#GetLocalTime(ARGUMENTS.TimeZone)#" cfsqltype="cf_sql_date">) 
				</cfquery>
	
				<cfcatch>
				<cfthrow detail="#cfcatch.message#">
				</cfcatch>
				
				</cftry>
				
			<cfelse>
			
				<cfthrow detail="AddInstanceError1">
			
			</cfif>	
				
			</cflock>

		</cfloop>
	
	</cfif>
		
	<!--- these two variables are only used on the front end when a single, top-level instance has been added --->
	<!--- so it doesn't matter that they are overwritten when looping over the array in this function when adding multiple instances --->
	<cfset response.InstanceID = NewInstance.GENERATED_KEY>
	<cfset response.InstanceName = InstanceName>
	<cfreturn response>
	
</cffunction>

<cffunction access="private" name="getChildren" returntype="string" output="false">
 
	<!--- Define arguments. --->
	<cfargument name="parentID" type="numeric" required="true"/>
	<cfargument name="addInstance" type="numeric" required="true"/>
 
<cfset var thelist = "">
 
<cfquery name="getChildNodes" datasource="jsaplus">
		SELECT n.PK_NodeID, NodeName
		FROM tbl_nodes n, tbl_nodestatus ns
		WHERE n.parentID = #ARGUMENTS.ParentID#
		AND n.PK_NodeID = ns.nodeID_FK
		AND (select Status from tbl_nodestatus where NodeID_FK = n.PK_NodeID order by pk_NodeStatusID desc limit 1) = 1
	</cfquery>
	
<cfoutput query="getchildNodes">
	
	<cfif NOT ARGUMENTS.addInstance>

		<cfquery name="CheckFieldGroups" datasource="jsaplus">
		select n.PK_NodeID
		from tbl_nodes n, tbl_fieldgroups fg
		where n.PK_NodeID = #PK_NodeID#
		and n.PK_NodeID = fg.NodeID_FK
		</cfquery>
		
		<cfif NOT CheckFieldGroups.recordcount>
		
			<cfset thelist = listAppend(thelist, PK_NodeID)>
	
		</cfif>
	
	<cfelse>

		<cfset thelist = listAppend(thelist, PK_NodeID)>
	
	</cfif>

	<cfset thelist = listAppend(thelist, getChildren(PK_NodeID, ARGUMENTS.AddInstance))>

</cfoutput>	

<cfreturn thelist>

</cffunction>

<cffunction name="CascadeUpdate" access="remote" returntype="struct" hint="I add forms to all children of the selected node">
	<!--- OtherInfo contains: NodeID, UserID, TimeZone, SiteID, FormType, FormName, FormCategory, InstanceID --->
	<cfargument type="array" name="NodeInfo" required="yes">
	<cfargument type="struct" name="OtherInfo" required="yes">
	
	<cfset var ChildNodes = "">
	<cfset var ChildNodesArray = ArrayNew(1)>
	<cfset var i = 0>
	<cfset var ii = 0>
	<cfset var ChildResponses = StructNew()>
	<cfset var ParentNodeID = ARGUMENTS.OtherInfo.NodeID>

	<cfset var response = StructNew()>

	<!--- first save the primary submitted nodeID form info --->
	<cfinvoke method="UpdateNodeInfo" returnvariable="UpdateReturnVariable">
		<cfinvokeargument name="NodeInfo" value="#ARGUMENTS.NodeInfo#">
		<cfinvokeargument name="OtherInfo" value="#ARGUMENTS.OtherInfo#">
	</cfinvoke>
			
	<!--- set the response from UpdateNodeInfo as the base response struct to be returned by this function --->
	<cfset response = UpdateReturnVariable>

	<!--- then get the children nodeIDs. The getChildren function excludes all child IDs that already have forms associated with them --->
	<cfinvoke method="getChildren" returnvariable="ChildNodes">
		<cfinvokeargument name="ParentID" value="#ARGUMENTS.OtherInfo.NodeID#">
		<cfinvokeargument name="AddInstance" value="#ARGUMENTS.OtherInfo.AddInstance#">
	</cfinvoke>
		
	<cfset ChildNodesArray = ListToArray(ChildNodes)>
	
	<!--- Loop over child IDs and call the UpdateNodeInfo function for each one --->
	<!--- Change OtherInfo.NodeID and call the Update function with the Cascade argument --->
	<!--- set FormName to empty string, so form only gets stored once --->
	<cfloop array="#ChildNodesArray#" index="i">
					
		<cfset ARGUMENTS.OtherInfo.NodeID = i>
		<cfset ARGUMENTS.OtherInfo.FormName = "">
			
		<cfinvoke method="UpdateNodeInfo" returnvariable="UpdateReturnVariable">
			<cfinvokeargument name="NodeInfo" value="#ARGUMENTS.NodeInfo#">
			<cfinvokeargument name="OtherInfo" value="#ARGUMENTS.OtherInfo#">
			<cfinvokeargument name="Cascade" value="#ParentNodeID#">
		</cfinvoke>
			
		<!--- append any messages to the structure that this function will return --->
		<cfif ArrayLen(UpdateReturnVariable.messages) gt 1>
				
			<cfloop array="#UpdateReturnVariable.messages#" index="ii">
				<cfif index gt 1>
					<cfscript>
						ArrayAppend(response.messages, UpdateReturnVariable.messages[ii]);			
					</cfscript>
				</cfif>
			</cfloop>
				
		</cfif>
			
	</cfloop> 

	<cfreturn response>

</cffunction>

<!--- TO DO: make response a structure or array that can send back multiple error messages --->
<cffunction name="UpdateNodeInfo" access="remote" returntype="struct" hint="I update form fields and data based on nodeInfo array passed from front end.">

	<cfargument type="array" name="NodeInfo" required="yes">
	<!--- OtherInfo contains: NodeID, UserID, TimeZone, SiteID, FormType, FormName, FormCategory, InstanceID --->
	<cfargument type="struct" name="OtherInfo" required="yes">
	<cfargument type="numeric" name="Cascade" required="no" default="0">

	<!--- formtypes: 0 = NodeInfo, 1= injuries, 2 = issues, 3 = comments,  4 = controls, 5 = MSDS, 6 = actions, 7 = audits --->
	<!--- form categories: 0=none,1=safety,2=quality,3=LEAN,4=sustainability,5=ergonomics --->
	
	<!--- Since Railo lacks the CF9 LOCAL scope, declare local variables with var keyword --->
	<cfset var response = StructNew()>
	<!--- create a list to hold FormGroupIDs, for use in saving the form at the end of the function --->
	<cfset var i = 0>
	<cfset var ii = 0>
	<cfset var iii = 0>
	<cfset var iv = 0>
	<cfset var v = 0>
	<cfset var vi = 0>
	<cfset var vii = 0>
	<cfset var AddFieldGroupResult = 0>
	<cfset var DeleteFieldGroupResult = "success">
	<cfset var AddFormFieldResult = 0>
	<cfset var DeleteFieldResult = "success">
	<cfset var getDisplayOrder = "">
	<cfset var FieldID = "">
	<cfset var FieldOptionID = "">
	<cfset var SavedForm = "">
	<cfset var checkFieldStatus = "">
	<cfset var CurrentInstanceID = ARGUMENTS.OtherInfo.InstanceID>
	<cfset var getInstance = "">
	<cfset var UpdateInstanceResult = "">
	<cfset var AddInstance = 0>
	<cfset var NewFile = "">
	
	<cfset response.messages = ArrayNew(1)>
	<cfset response.instanceID = 0>
	<cfset response.InstanceName = "">
	<cfset response.formType = ARGUMENTS.OtherInfo.FormType>
	<cfset response.cascade = ARGUMENTS.cascade>
	<cfset response.messages[1] = "default">

	<!--- we will use transaction processing for this. If anything fails, nothing will be committed, giving the user --->
	<!--- an opportunity to resubmit the form --->
	<!--- <cftransaction> --->
	
	<!--- save new instance if appropriate --->
 	<cfif ARGUMENTS.OtherInfo.addInstance> 

		<cfset AddInstance = 1>
	
		<cfinvoke method="UpdateInstances" returnvariable="UpdateInstanceResult">
			<cfinvokeargument name="ProcessID" value="#ARGUMENTS.OtherInfo.NodeID#">
			<cfinvokeargument name="InstanceID" value="#CurrentInstanceID#">
			<cfinvokeargument name="FormCategory" value="#ARGUMENTS.OtherInfo.FormCategory#">
			<cfinvokeargument name="FormType" value="#ARGUMENTS.OtherInfo.FormType#">
			<cfinvokeargument name="SelectedNodes" value="#ARGUMENTS.OtherInfo.SelectedNodes#">
			<cfinvokeargument name="UserID" value="#ARGUMENTS.OtherInfo.UserID#">
			<cfinvokeargument name="TimeZone" value="#ARGUMENTS.OtherInfo.TimeZone#">
		</cfinvoke>

		<cfif updateInstanceResult.message eq "success">
		<cfset CurrentInstanceID = updateInstanceResult.InstanceID>
		<cfset response.messages[1] = "InstanceAdded">
		<cfset response.InstanceName = updateInstanceResult.InstanceName>
		
		<cfelse>
		<cfthrow message="#updateInstanceResult.message#">
		</cfif>

	<!--- if we're updating an existing instance, get the instance name --->
	<cfelseif ARGUMENTS.OtherInfo.InstanceID>
		
		<cfquery name="getInstanceName" datasource="jsaplus">
		select InstanceName from tbl_instances
		where PK_InstanceID = <cfqueryparam value="#ARGUMENTS.OtherInfo.InstanceID#" cfsqltype="cf_sql_integer">
		</cfquery>
		
		<cfif getInstanceName.recordcount>
			<cfset response.InstanceName = getInstanceName.InstanceName>
		</cfif>
			
	</cfif>
	
	<cfset response.InstanceID = CurrentInstanceID>

	<!---  LOOP OVER THE OUTER ARRAY (DATA FIELD GROUPS) --->
	<!--- Each index in the outer array holds an entire field group, including the group label (first item in the inner array) --->
	<!--- and any data fields that have been added to the group (subsequent items in the inner array) --->
	<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo)#" index="i">
	
		<cfset AddFieldGroupResult = 0>
		
		<!--- LOOP OVER THE INNER ARRAY (THE DATA FIELD GROUP ID AND LABEL [first index] AND DATA FIELDS [subsequent indexes]) --->
		<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i])#" index="ii">
		
			<!--- need to (re)set these to 0 at beginning of loops --->
			<cfset AddFormFieldResult = 0>
			
			<!--- FIRST INDEX IN INNER ARRAY HOLDS DATA GROUP LABEL --->
			<!--- BACKEND (CF) ARRAYS BEGIN WITH 1, FRONTEND (AS) ARRAYS BEGIN WITH 0 --->
			<cfif ii eq 1>
			
				<!--- ADD data field group (a FIELDGROUPID of 0 signals ADD a field group) --->
				<!--- we also run this function if we're adding an instance, as long as the delete flag is not set --->
				<cfif (ARGUMENTS.nodeInfo[i][ii]["FieldGroupID"] eq 0 OR AddInstance OR ARGUMENTS.Cascade) AND ARGUMENTS.nodeInfo[i][ii]["Label"]["Update"] neq 2>
			
					<cfinvoke method="AddFieldGroup" returntype="numeric" returnVariable="AddFieldGroupResult">
						<cfinvokeargument name="NodeID" value="#ARGUMENTS.OtherInfo.NodeID#">
						<cfinvokeargument name="GroupLabel" value="#ARGUMENTS.NodeInfo[i][ii]['Label']['Content']#">
						<cfinvokeargument name="FormType" value="#ARGUMENTS.OtherInfo.FormType#">
						<cfinvokeargument name="UserID" value="#ARGUMENTS.OtherInfo.UserID#">
						<cfinvokeargument name="TimeZone" value="#ARGUMENTS.OtherInfo.TimeZone#">
						<cfif isNumeric(ARGUMENTS.nodeInfo[i][ii]['FieldGroupOrder'])>
							<cfinvokeargument name="DisplayOrder" value="#ARGUMENTS.nodeInfo[i][ii]['FieldGroupOrder']#">
						<cfelse>
							<cfinvokeargument name="DisplayOrder" value="#i#">
						</cfif>	
						<cfinvokeargument name="InstanceID" value="#CurrentInstanceID#">
					</cfinvoke>
					<!--- if there was an error adding the new form group, stop processing --->
					<cfif NOT AddFieldGroupResult>
						<!---<cftransaction action = "rollback"/>---> 
						<cfthrow detail="AddFieldGroupError1">
					</cfif>
				
				<!--- if we're dealing with an existing field that we're not deleting, record the FieldGroupOrder, --->
				<!--- and make sure the group status is set to active --->
				<cfelseif ARGUMENTS.NodeInfo[i][ii]["Label"]["Update"] neq 2>

					<cfinvoke method="SetFieldGroupOrder" returntype="numeric" returnVariable="SetFieldGroupOrderResult">
						<cfinvokeargument name="FieldGroupID" value="#ARGUMENTS.nodeInfo[i][ii]['FieldGroupID']#">
						<cfinvokeargument name="DisplayOrder" value="#ARGUMENTS.nodeInfo[i][ii]['FieldGroupOrder']#">
					</cfinvoke>

					<!--- we don't stop processing for display order errors --->
					<cfif NOT SetFieldGroupOrderResult>
						<cfscript>
						ArrayAppend(response.messages, "DisplayOrderError");
						</cfscript>
					</cfif>
					
					<!--- if the last status record for this field group is set to 0 and there is only one status record for the field group, 
					the group was just added because a file upload field was added --->
					<!--- (see comment at AddFieldGroup function) --->
					<!--- in this one case, we will change the status to 1 rather than add a new record --->
					<cftry>

					<cfquery name="checkFieldGroupStatus" datasource="jsaplus">
					select Status, PK_FieldGroupStatusID from tbl_fieldgroupstatus 
					where FieldGroupID_FK = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldGroupID']#" cfsqltype="cf_sql_integer"> 
					order by pk_fieldGroupStatusID desc 
					</cfquery>
					
					<cfcatch>
					
					<!---<cftransaction action = "rollback"/>--->
					<cfthrow detail="AddFieldGroupError2">
					</cfcatch>
					
					</cftry>
					
					<!--- if there's just one record and the status is 0, we need to update the status table --->
					<cfif checkFieldGroupStatus.Status eq 0 and CheckFieldGroupStatus.recordcount eq 1>
					
					<cftry>
					
					<cfquery name="updategroupstatus" datasource="jsaplus">
					update tbl_fieldgroupstatus
					set Status = 1
					where PK_FieldGroupStatusID = <cfqueryparam value="#CheckFieldGroupStatus.PK_FieldGroupStatusID#" cfsqltype="cf_sql_integer">
					</cfquery>
					
					<cfcatch>
										

					<!---<cftransaction action = "rollback"/>--->
					<!--- this is in effect an add field group error --->
					<cfthrow detail="AddFieldGroupError3">
					</cfcatch>
					
					</cftry>

					</cfif>
				
				</cfif>
	
				<!--- DELETE data group (a LABEL UPDATE flag of 2 signals DELETE THE GROUP) --->
				<!--- (don't run this if we're adding an instance or doing a cascade save) --->
				<!--- this if ...elseif block needs to be here, not added to the above block --->
				<cfif ARGUMENTS.nodeInfo[i][ii]["FieldGroupID"] neq 0 AND ARGUMENTS.NodeInfo[i][ii]["Label"]["Update"] eq 2 AND NOT AddInstance AND NOT ARGUMENTS.Cascade>
					
					<cfinvoke method="DeleteFieldGroup" returntype="string" returnVariable="DeleteFieldGroupResult">
						<cfinvokeargument name="FieldGroupID" value="#ARGUMENTS.nodeInfo[i][ii]['FieldGroupID']#">
						<cfinvokeargument name="UserID" value="#ARGUMENTS.OtherInfo.UserID#">
						<cfinvokeargument name="TimeZone" value="#ARGUMENTS.OtherInfo.TimeZone#">
					</cfinvoke>
					
					<!--- we will not stop processing for delete errors --->
					<cfif NOT deleteFieldGroupResult>
					<cfscript>
					ArrayAppend(response.messages, "DeleteFieldGroupError");
					</cfscript>
					</cfif>
					
				<!--- UPDATE the field group label if necessary (a LABEL UPDATE flag of 1 signals UPDATE THE LABEL) --->
				<!--- displayorder has already been recorded above --->
				<cfelseif ARGUMENTS.nodeInfo[i][ii]["Label"]["Update"] eq 1 AND ARGUMENTS.nodeInfo[i][ii]['FieldGroupID'] neq 0 AND NOT AddInstance AND NOT ARGUMENTS.Cascade>
	
					<cftry>
					
					<!--- for labels we simply update the information; we are not tracking these changes --->
					<cfquery name="updategroup" datasource="jsaplus">
					update tbl_FieldGroups
					set FieldGroupLabel = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Label']['Content']#" cfsqltype="cf_sql_varchar">
					where PK_FieldGroupID = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldGroupID']#" cfsqltype="cf_sql_integer">
					</cfquery>
					
					<cfcatch>
					<!--- we will not stop processing for update label errors --->
					<cfscript>
					ArrayAppend(response.messages, "UpdateFieldGroupLabelError");
					</cfscript>
					</cfcatch>
					
					</cftry>
					
				</cfif>
				
			<!--- SUBSEQUENT INDEXES (greater than 1) IN THE INNER ARRAY HOLD DATA FIELDS --->
			<cfelse>
				
				<!--- NEW DATA FIELD CODE (a field ID of 0 means add a field) --->
				<cfif (ARGUMENTS.nodeInfo[i][ii]["FieldID"] eq 0 OR AddInstance OR ARGUMENTS.Cascade) AND ARGUMENTS.nodeInfo[i][ii]["Label"]["Update"] neq 2>
					
					<cfinvoke method="addFormField" returntype="numeric" returnVariable="addFormFieldResult">
						<cfinvokeargument name="newFormField" value="#ARGUMENTS.nodeInfo[i][ii]#">
						
						<!--- if we're not adding an instance and there's an existing FieldGroupID, we're adding the field to that group --->
						<cfif NOT AddInstance AND NOT ARGUMENTS.Cascade AND ARGUMENTS.nodeInfo[i][1]["FieldGroupID"] gt 0>
							<cfinvokeargument name="FieldGroupID" value="#ARGUMENTS.nodeInfo[i][1]['FieldGroupID']#">
						<cfelse>
							<!--- otherwise we're adding to the group just created above --->
							<cfinvokeargument name="FieldGroupID" value="#AddFieldGroupResult#">
						</cfif>
						
						<cfinvokeargument name="UserID" value="#ARGUMENTS.OtherInfo.UserID#">
						<cfinvokeargument name="TimeZone" value="#ARGUMENTS.OtherInfo.TimeZone#">
						<cfif isNumeric(ARGUMENTS.nodeInfo[i][ii]['FieldOrder'])>
							<cfinvokeargument name="DisplayOrder" value="#ARGUMENTS.nodeInfo[i][ii]['FieldOrder']#">
						<cfelse>
							<cfinvokeargument name="DisplayOrder" value="#ii#">
						</cfif>					
					</cfinvoke>
					
					<cfif NOT AddFormFieldResult>
						<!---<cftransaction action = "rollback"/>--->
						<cfthrow message="AddFormFieldError">
					</cfif>
					
				</cfif>
					
				<!--- EXISTING DATA FIELD CODE --->
				<!---(ALSO HANDLES NEW DATA FIELDS WITH DATA ADDED ON FRONT END BEFORE THE FIELD HAS BEEN ADDED HERE) --->

				<!--- DELETE DATA FIELD CODE (label update flag of 2 signals delete) --->
				<!--- (don't run this if we're adding an instance or doing a cascade save) --->
				<cfif ARGUMENTS.nodeInfo[i][ii]["Label"]["Update"] eq 2 AND ARGUMENTS.nodeInfo[i][ii]['FieldID'] neq 0 AND NOT AddInstance AND NOT ARGUMENTS.Cascade>
					
					<cfinvoke method="deleteField" returntype="string" returnVariable="DeleteFieldResult">
						<cfinvokeargument name="FieldID" value="#ARGUMENTS.nodeInfo[i][ii]['FieldID']#">
						<cfinvokeargument name="UserID" value="#ARGUMENTS.OtherInfo.UserID#">
						<cfinvokeargument name="TimeZone" value="#ARGUMENTS.OtherInfo.TimeZone#">
					</cfinvoke>
			
					<cfif NOT deleteFieldResult>
						<!--- we will not stop processing for delete field errors --->
						<cfscript>
						ArrayAppend(response.messages, "DeleteFieldError");
						</cfscript>
					</cfif>
					
				<!--- UPDATE DATA FIELD LABEL --->
				<!--- again, do not run this if we're adding an instance or doing a cascade save --->
				<cfelseif ARGUMENTS.nodeInfo[i][ii]["Label"]["Update"] eq 1 AND ARGUMENTS.nodeInfo[i][ii]['FieldID'] neq 0 AND NOT AddInstance AND NOT ARGUMENTS.Cascade>
						
						<!--- for labels we simply update the information; we are not tracking these changes --->
						<cftry>
						
						<cfquery name="updatefields" datasource="jsaplus">
						update tbl_Fields
						set FieldLabel = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Label']['Content']#" cfsqltype="cf_sql_varchar">
						<cfif ARGUMENTS.nodeInfo[i][ii]["FieldID"] neq 0>
						where PK_FieldID = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldID']#" cfsqltype="cf_sql_integer">
						<cfelse>
						where PK_FieldID = <cfqueryparam value="#AddFormFieldResult#" cfsqltype="cf_sql_integer">
						</cfif>
						</cfquery>
						
						<cfcatch>
						<!--- we will not stop processing for update field label errors --->
						<cfscript>
						ArrayAppend(response.messages, "UpdateFieldLabelError");
						</cfscript>

						</cfcatch>
						
						</cftry> 
				
				</cfif> 
					
				<!--- UPDATE DATA FIELD DATA AND DATA FIELD DISPLAY ORDER --->
				<!--- NOTE there is also code in the case condition "FileUpload" to set the fieldstatus to active when necessary --->

				<!--- reset loop index used within the switch block --->
				<cfset iii = 0>
				
				<!--- we need to set these here, NOT right after the AddFormField function call --->
				<cfif AddFormFieldResult>
					
					<cfset FieldID = AddFormFieldResult>
					
				<cfelse>
					
					<cfset FieldID = ARGUMENTS.nodeInfo[i][ii]['FieldID']>
					
				</cfif>	

				<!--- don't run data update (switch code) or display order update if the field is being deleted (label update flag 2 signals delete)--->
				<cfif ARGUMENTS.nodeInfo[i][ii]["Label"]["Update"] neq 2>
					
					<!--- check for the field type and run appropriate update code when the update flag indicates --->
					<cfswitch expression="#ARGUMENTS.nodeInfo[i][ii]['FieldType']#">
	
						<cfcase value="TextInput">
				
							<cfif ARGUMENTS.nodeInfo[i][ii]["Data"]["Update"] eq 1>
							
								<!--- insert the new information into the shorttext table. For tracking purposes, we are --->
								<!--- adding a new record to the database not only when the data is first entered but --->
								<!--- each time it is changed. We record the User and Date/Time as well --->
								<cftry>
								
								<cfquery name="addfielddata" datasource="jsaplus">
								insert into tbl_fielddata_shorttext(fieldid_fk, data, userid_fk, datemodified)  
								values(<cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Data']['Content']#" cfsqltype="cf_sql_varchar">, 
									<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
									<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="cf_sql_date">)
								</cfquery>
								
								<cfcatch>
								<!---<cftransaction action = "rollback"/>--->
								<cfthrow message="UpdateDataError">
								</cfcatch>
								
								</cftry>
		
							</cfif>				
					
						</cfcase>
	
						<cfcase value="TextArea">
		
							<cfif ARGUMENTS.nodeInfo[i][ii]["Data"]["Update"] eq 1>
							
								<!--- insert the new information. See comment above at TextInput re tracking --->
								<cftry>
								
								<cfquery name="addfielddata" datasource="jsaplus">
								insert into tbl_fielddata_longtext(fieldid_fk, data, userid_fk, datemodified)  
								values(<cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Data']['Content']#" cfsqltype="cf_sql_longvarchar">,
								<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
								<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="cf_sql_date">)
								</cfquery>
								
								<cfcatch>
								<!---<cftransaction action = "rollback"/>--->
								<cfthrow message="UpdateDataError">
								</cfcatch>
								
								</cftry>
		
							</cfif>				
		
						</cfcase>
		
						<cfcase value="DateField">
		
							<cfif ARGUMENTS.nodeInfo[i][ii]["Data"]["Update"] eq 1>
							
							<!--- insert the new information. See comment above at TextInput re tracking --->
							<cftry>
							
							<cfquery name="addfielddata" datasource="jsaplus">
							insert into tbl_fielddata_date(fieldid_fk, data, userid_fk, datemodified)  
							values(<cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">,
							<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Data']['Content']#" cfsqltype="cf_sql_date">, 
							<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
							<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="cf_sql_date">)
							</cfquery>
		
							<cfcatch>
							<!---<cftransaction action = "rollback"/>--->
							<cfthrow message="UpdateDataError">
							</cfcatch>
								
							</cftry>
							
							</cfif>				
		
						</cfcase>
	
						<cfcase value="CheckBox,CalcCheckBox,RadioGroup,CalcRadioGroup,CalcBoolean,DropDownList">
						
							<!--- loop over field options in nodeInfo array and set item's status accordingly, or add new items --->
							<!--- update status by ADDING records to the fieldoptionsstatus table, not by updating existing records ---> 
							<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i][ii]['FieldOptions'])#" index="iii">	
							
								<!--- add a new field option if indicated. Do not add the field option if it was added and then deleted on the 
								front end before even submitted here (update flag 2) --->
								<cfif (ARGUMENTS.nodeInfo[i][ii]["FieldOptions"][iii]["FieldOptionID"] eq 0 OR AddInstance OR ARGUMENTS.Cascade) AND ARGUMENTS.nodeInfo[i][ii]["FieldOptions"][iii]["Update"] neq 2>
								
									<cfinvoke method="addFieldOption" returnVariable="AddFieldOptionResult">
									
										<cfinvokeargument name="FieldID" value="#FieldID#">
										<cfinvokeargument name="Content" value="#ARGUMENTS.nodeInfo[i][ii]['FieldOptions'][iii]['Label']#">
										<cfinvokeargument name="UserID" value="#ARGUMENTS.OtherInfo.UserID#">										
										<cfinvokeargument name="TimeZone" value="#ARGUMENTS.OtherInfo.TimeZone#">
										
										<cfif ARGUMENTS.nodeInfo[i][ii]['FieldType'] eq "CalcCheckBox" OR ARGUMENTS.nodeInfo[i][ii]['FieldType'] eq "CalcRadioGroup" OR ARGUMENTS.nodeInfo[i][ii]['FieldType'] eq "CalcBoolean">

											<cfinvokeargument name="Value" value="#ARGUMENTS.nodeInfo[i][ii]['FieldOptions'][iii]['Value']#">

										</cfif>  
																				
									</cfinvoke>
									
									<cfif NOT AddFieldOptionResult>
										<!---<cftransaction action = "rollback"/>--->
										<cfthrow message="AddFieldOptionError">
									</cfif>  
								
									<cfset FieldOptionID = AddFieldOptionResult> 
								
								<cfelse>
								
									<cfset FieldOptionID = ARGUMENTS.nodeInfo[i][ii]["FieldOptions"][iii]["FieldOptionID"]>

								</cfif>
								
								<!--- update existing field option status (to selected or (for checkboxes only) deselected) --->
								<!--- NOTE: This will also update the status of a new field option that the user changed --->
								<!--- on the front end after creating it; we treat it here as an "existing" field option --->
								<!--- using the newly created FieldOptionID --->
								<cfif ARGUMENTS.nodeInfo[i][ii]["FieldOptions"][iii]["Update"] eq 1>
								
									<cftry>
									
									<cfquery name="addfieldoptionstatus" datasource="jsaplus">
									insert into tbl_fieldoptionsstatus(FieldOptionID_FK, Status, UserID_FK, DateModified)
									values(<cfqueryparam value="#FieldOptionID#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldOptions'][iii]['Status']#" cfsqltype="CF_SQL_INTEGER">, 
									<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
									<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="CF_SQL_date">)
									</cfquery>
									
									<cfcatch>
									<!---<cftransaction action = "rollback"/>--->
									<cfthrow message="UpdateFieldOptionError">
									</cfcatch>
									
									</cftry>
									
								<!--- set existing field option status to deleted --->
								<cfelseif ARGUMENTS.nodeInfo[i][ii]["FieldOptions"][iii]["Update"] eq 2>	
								
									<cftry>
									
									<cfquery name="addfieldoptionstatus" datasource="jsaplus">
									insert into tbl_fieldoptionsstatus(FieldOptionID_FK, Status, UserID_FK, DateModified)
									values(<cfqueryparam value="#FieldOptionID#" cfsqltype="CF_SQL_INTEGER">,
									3, 
									<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
									<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="CF_SQL_date">)
									</cfquery>
									
									<cfcatch>
									<!--- we will not stop processing for field option delete errors --->
									<cfscript>
									ArrayAppend(response.messages, "DeleteFieldOptionError");
									</cfscript>
									</cfcatch>
									
									</cftry>
								
								</cfif>
						
							</cfloop>
		
						</cfcase>
					
						<cfcase value="NumericStepper">
		
							<cfif AddInstance OR ARGUMENTS.Cascade OR ARGUMENTS.nodeInfo[i][ii]["FieldID"] eq 0 OR ARGUMENTS.nodeInfo[i][ii]["Data"]["Update"] eq 1>
							
								<!--- we are storing the numeric stepper data in the shorttext table --->
								<cftry>
								
								<cfquery datasource="jsaplus" name="addfielddata" result="addthedata">
								insert into tbl_fielddata_shorttext(fieldid_fk, data, userid_fk, datemodified)  
								values(<cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">,
									<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Data']['Content']#" cfsqltype="cf_sql_varchar">, 
									<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
									<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="cf_sql_date">)
								</cfquery>
								
								<cfcatch>
								<!---<cftransaction action = "rollback"/>--->
								<cfthrow message="UpdateDataError">
								</cfcatch>
								
								</cftry>
		
							</cfif>		
							
							<cfif ARGUMENTS.nodeInfo[i][ii]["FieldID"] eq 0 OR AddInstance OR ARGUMENTS.Cascade>
							
								<cftry>
								
								<cfquery name="addsteppersettings" datasource="jsaplus">
								insert into tbl_stepper_settings(FieldID_FK,StepSize,Min,Max)
								values(<cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['StepSize']#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['Min']#" cfsqltype="cf_sql_integer">,
								<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['Max']#" cfsqltype="cf_sql_integer">)
								</cfquery>
								
								<cfcatch>
								<!--- we WILL stop processing if stepper settings are not recorded --->
								<!--- <!---<cftransaction action = "rollback"/>--->
								<cfthrow message="UpdateStepperError"> --->
								</cfcatch>
								
								</cftry>
							
							<cfelseif ARGUMENTS.nodeInfo[i][ii]["StepperSettings"]["Update"] eq 1>
							
								<cftry>
								
								<cfquery name="upodatesteppersettings" datasource="jsaplus">
								update tbl_stepper_settings
								set StepSize = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['StepSize']#" cfsqltype="cf_sql_integer">,
								Min = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['Min']#" cfsqltype="cf_sql_integer">,
								Max = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['Max']#" cfsqltype="cf_sql_integer">
								where FieldID_FK = <cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">
								</cfquery>
								
								<cfcatch>
								<!--- we will NOT stop processing for update stepper settings errors --->
								<cfscript>
								ArrayAppend(response.messages, "UpdateStepperSettingsError");
								</cfscript>
								</cfcatch>
								
								</cftry>
							
							</cfif>
		
						</cfcase>
					
						<cfcase value="FileUpload">
						
							<!--- check field status for fileUpload fields, which may have just been added by the front end upload function --->
							<!--- (this will not be the case for Cascade saves) --->
							<!--- if the last status record for this field is set to 0 and there is only one status record for the field, ---> 
							<!--- then the field was just added (see comment at AddFieldGroup function) --->
							<!--- in this case, we will change the status to 1 rather than add a new record --->
							<cfif NOT AddInstance AND NOT ARGUMENTS.Cascade>
							
								<cftry>
	
								<cfquery name="checkFieldStatus" datasource="jsaplus">
								select Status, PK_FieldStatusID from tbl_fieldstatus 
								where FieldID_FK = <cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer"> 
								order by PK_FieldStatusID desc 
								</cfquery>
								
								<cfcatch>
								<!--- this is in efect an add field error --->
								<!---<cftransaction action = "rollback"/>--->
								<cfthrow detail="AddFieldError">
								</cfcatch>
								
								</cftry>
								
								<!--- if there's just one record and the status is 0, we need to update the status table --->
								<cfif CheckFieldStatus.recordcount eq 1 AND checkFieldStatus.Status eq 0>
								
									<cftry>
									
									<cfquery name="updatefieldstatus" datasource="jsaplus">
									update tbl_fieldstatus
									set Status = 1
									where PK_FieldStatusID = <cfqueryparam value="#CheckFieldStatus.PK_FieldStatusID#" cfsqltype="cf_sql_integer">
									</cfquery>
									
									<cfcatch>
									<!---<cftransaction action = "rollback"/>--->
									<!--- this is in effect an add field error --->
									<cfthrow detail="AddFieldError">
									</cfcatch>
									
									</cftry>
								
								</cfif>
							
							<!--- now handle cascade and instance saves --->
							<cfelse>
							
								<!--- save to the files table --->
								<!--- store the new FieldID under FieldID_FK and the "parent" fileID as the FileID_FK  --->
								<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i][ii]['Files'])#" index="vii">
								
									<!--- don't save anything if update is set to 1 (which means delete here) --->
									
									<!--- NOTE: see note in GetFormInfo function regarding use of FieldID_FK and FileID_FK values --->
									<!--- do not confuse the use of FileID_FK in tbl_files and tbl_filestatus, they are different --->
									<cfif ARGUMENTS.nodeInfo[i][ii]["Files"][vii]["Update"] neq 1>
									
										<cftry>

										<cfquery datasource="jsaplus" result="NewFile">
										insert into tbl_files(FieldID_FK, FileName, FileExt, FileID_FK)
										values(<cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">, 
										<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Files'][vii]['FileName']#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Files'][vii]['FileExt']#" cfsqltype="cf_sql_varchar">,
										<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Files'][vii]['FileID']#" cfsqltype="cf_sql_integer">)
										</cfquery>
										
										<cfcatch>
										<!---<cftransaction action = "rollback"/>--->
										<!--- this is in effect an add field error --->
										<cfthrow detail="#cfcatch.detail#">
										</cfcatch>
										
										</cftry>
									
										<cftry>

										<cfquery datasource="jsaplus">
										insert into tbl_filestatus(FileID_FK, Status, UserID_FK, DateModified)
										values(<cfqueryparam value="#NewFile.GENERATED_KEY#" cfsqltype="cf_sql_integer">, 
										1, 
										<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
										<cfqueryparam value="#DateAdd("h", OtherInfo.TimeZone, Now())#" cfsqltype="cf_sql_date">)
										</cfquery>
									
										<cfcatch>
										<!---<cftransaction action = "rollback"/>--->
										<!--- this is in effect an add field error --->
										<cfthrow detail="AddFieldError2">
										</cfcatch>
										
										</cftry>

									</cfif>
								
								</cfloop>
								
							</cfif>
							
							<!--- now handle deleted files --->
							<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i][ii]['Files'])#" index="iii">
							
								<!--- an update flag of 1 here means to delete the file --->
								<cfif ARGUMENTS.nodeInfo[i][ii]["Files"][iii]["Update"] eq 1>
								<!--- <cfif 1 eq 0> --->
								
								<cftry>
								
								<!--- add a record to the filestatus table with status 0 for deleted --->
								<cfquery name="addfilestatus" datasource="jsaplus">
								insert into tbl_filestatus(FileID_FK, Status, UserID_FK, DateModified)
									values(<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Files'][iii]['FileID']#" cfsqltype="cf_sql_integer">, 
									0, 
									<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">, 
									<cfqueryparam value="#Now()#" cfsqltype="cf_sql_date">)
									</cfquery>
									
								<!--- we do not stop processing for file delete errors --->
								<cfcatch>
								<cfscript>
								ArrayAppend(response, "FileDeleteError");
								</cfscript>
								</cfcatch>
								
								</cftry>	
																	
								</cfif>
							
							</cfloop>
							
						</cfcase>
						
					</cfswitch>
					
						
					<!--- update display order; don't need to do this for new fields --->
					<cfif ARGUMENTS.nodeInfo[i][ii]['FieldID'] neq 0>
					
						<cftry>
						
						<cfquery name="updatefield" datasource="jsaplus">
						update tbl_fields
						set DisplayOrder = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldOrder']#" cfsqltype="cf_sql_integer"> 
						where PK_FieldID = <cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldID']#" cfsqltype="cf_sql_integer">
						</cfquery>
						
						<cfcatch>
						<!--- we will not stop processing for ordering errors --->
						<cfscript>
						ArrayAppend(response.messages, "DisplayOrderError");
						</cfscript>
						</cfcatch>
						
						</cftry>
			
					</cfif>

				<!--- this ends the "if" condition that runs when we are updating a data field rather than deleting one --->
				</cfif>
					
				<cfif ArrayLen(ARGUMENTS.nodeInfo[i][ii]['Comments'])>

				<!--- ADD COMMENTS CODE --->
				<!--- reset the loop index used to save comments --->
				<cfset iv = 0>
				<!--- loop over the comments array. if the array is empty  nothing happens here --->
				<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i][ii]['Comments'])#" index="iv">	

					<cfif ARGUMENTS.nodeInfo[i][ii]["Comments"][iv]["Update"] eq 1>
						
						<cftry>
						
						<cfquery name="addcomment" datasource="jsaplus">
						insert into tbl_field_comments(FieldComment,FieldID_FK,UserID_FK,DateModified)
						values(<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Comments'][iv]['Content']#" cfsqltype="cf_sql_varchar">,
						<cfqueryparam value="#FieldID#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">,
						<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="cf_sql_date">)
						</cfquery>
						
						<cfcatch>
						<!--- we do not stop processing for add comment errors --->
						<cfscript>
						ArrayAppend(response.messages, "AddCommentError");
						</cfscript>
						</cfcatch>
						
						</cftry>
						
					</cfif>

				</cfloop>	
				
				</cfif>			
			
			<!--- this ends the "else" condition that runs when the inner array index is greater than 1 (i.e. when we are dealing with a data field not a data field group) --->
			</cfif>
		
		</cfloop>
	
	</cfloop>
	
	<!--- </cftransaction> --->
	
	<!--- save the form name if appropriate --->
	<cfif ARGUMENTS.OtherInfo.FormName neq "">
	
		<!--- if the user wants the saved form to be a master form, see if there is already a master form for the form type and if so make it a regular form --->
		<!--- the front end will have already warned the user that the previous master form will be replaced --->
		<cfif ARGUMENTS.OtherInfo.MasterForm>
		
			
			
			<cftry>

			<cfquery name="CheckForMaster" datasource="jsaplus">
			select f.PK_SavedFormID, f.FormName
			from tbl_savedforms f, tbl_savedforms_fieldgroups fg
			where fg.SavedFormID_FK = f.PK_SavedFormID
			and f.SiteID_FK = <cfqueryparam value="#ARGUMENTS.OtherInfo.SiteID#" cfsqltype="cf_sql_integer"> 
			and f.MasterForm = 1
			and fg.FormType = <cfqueryparam value="#ARGUMENTS.OtherInfo.FormType#" cfsqltype="cf_sql_integer">
			</cfquery>
			
			<cfcatch>
			<!--- we do not stop processing for form save errors --->
			<cfscript>
			ArrayAppend(response.messages, "FormSaveError");
			</cfscript>
			<cfreturn response>
			</cfcatch>
			
			</cftry>
			
			<cfif CheckForMaster.recordcount>
			
	
				<cfloop query="CheckForMaster">
				
					<cftry>

					<cfquery name="UpdateMaster" datasource="jsaplus">
					update tbl_savedforms
					set MasterForm = 0
					where PK_SavedFormID = <cfqueryparam value="#CheckForMaster.PK_SavedFormID#" cfsqltype="cf_sql_integer"> 
					</cfquery>				
				
					<cfcatch>
					<!--- we do not stop processing for form save errors --->
					<cfscript>
					ArrayAppend(response.messages, "FormSaveError");
					</cfscript>
					<cfreturn response>
					</cfcatch>
					
					</cftry>

				</cfloop>
				
			</cfif>
			
		</cfif>

		<cftry>
			
		<cfquery datasource="jsaplus" name="addsavedform" result="SavedForm">
		insert into tbl_savedforms(FormName, SiteID_FK, NodeID_FK, UserID_FK, DateModified, MasterForm)
		values(<cfqueryparam value="#ARGUMENTS.OtherInfo.FormName#" cfsqltype="cf_sql_varchar">,
		<cfqueryparam value="#ARGUMENTS.OtherInfo.SiteID#" cfsqltype="cf_sql_integer">,
		<cfqueryparam value="#ARGUMENTS.OtherInfo.NodeID#" cfsqltype="cf_sql_integer">,
		<cfqueryparam value="#ARGUMENTS.OtherInfo.UserID#" cfsqltype="cf_sql_integer">,
		<cfqueryparam value="#GetLocalTime(ARGUMENTS.OtherInfo.TimeZone)#" cfsqltype="cf_sql_date">,
		<cfif ARGUMENTS.OtherInfo.MasterForm>1<cfelse>0</cfif>)
		</cfquery>
		
		<cfcatch>
		<!--- we do not stop processing for form save errors --->
		<cfscript>
		ArrayAppend(response.messages, "FormSaveError");
		</cfscript>
		<cfreturn response>
		</cfcatch>
		
		</cftry>
		
		<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo)#" index="i">
		
			<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i])#" index="ii">
			
				<cfif ii eq 1>
		
					<cftry>
					
					<cfquery name="addsavedfieldgroup" datasource="jsaplus" result="SavedFieldGroup">
					insert into tbl_savedforms_fieldgroups(SavedFormID_FK,FieldGroupLabel,DisplayOrder,FormType)
					values(<cfqueryparam value="#SavedForm.GENERATED_KEY#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Label']['Content']#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldGroupOrder']#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#ARGUMENTS.OtherInfo.FormType#" cfsqltype="cf_sql_integer">)
					</cfquery>
					
					<cfcatch>
					<!--- we do not stop processing for form save errors --->
					<cfscript>
					ArrayAppend(response.messages, "FormSaveError");
					</cfscript>
					<cfreturn response>
					</cfcatch>
					
					</cftry>
			
				<cfelse>	
			
					<cftry>
					
					<cfquery name="addsavedfield" datasource="jsaplus" result="SavedField">
					insert into tbl_savedforms_fields(SavedFieldGroupID_FK,FieldLabel,FieldType,DisplayOrder)
					values(<cfqueryparam value="#SavedFieldGroup.GENERATED_KEY#" cfsqltype="cf_sql_integer">,
					<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['Label']['Content']#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldType']#" cfsqltype="cf_sql_varchar">,
					<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldOrder']#" cfsqltype="cf_sql_integer">)
					</cfquery>
					
					<cfcatch>
					<!--- we do not stop processing for form save errors --->
					<cfscript>
					ArrayAppend(response.messages, "FormSaveError");
					</cfscript>
					<cfreturn response>
					</cfcatch>
					
					</cftry>
					
					<cfif ARGUMENTS.nodeInfo[i][ii]["FieldType"] eq "CheckBox" or ARGUMENTS.nodeInfo[i][ii]["FieldType"] eq "RadioGroup" OR ARGUMENTS.nodeInfo[i][ii]["FieldType"] eq "DropDownList">
			
						<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i][ii]['FieldOptions'])#" index="iii">
							
							<cftry>
							
							<cfquery name="addsavedfieldoption" datasource="jsaplus">
							insert into tbl_savedforms_fieldoptions(SavedFieldID_FK, FieldOptionLabel)
							values(<cfqueryparam value="#SavedField.GENERATED_KEY#" cfsqltype="cf_sql_integer">,
							<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldOptions'][iii]['Label']#" cfsqltype="cf_sql_varchar">)
							</cfquery>
	
							<cfcatch>
							<!--- we do not stop processing for form save errors --->
							<cfscript>
							ArrayAppend(response.messages, "FormSaveError");
							</cfscript>
							</cfcatch>
							
							</cftry>
							
						</cfloop>
			
					<cfelseif ARGUMENTS.nodeInfo[i][ii]["FieldType"] eq "CalcCheckBox" OR ARGUMENTS.nodeInfo[i][ii]["FieldType"] eq "CalcRadioGroup" OR ARGUMENTS.nodeInfo[i][ii]["FieldType"] eq "CalcBoolean">
					
						<cfloop from="1" to="#ArrayLen(ARGUMENTS.nodeInfo[i][ii]['FieldOptions'])#" index="iii">
							
							<cftry>
							
							<cfquery name="addsavedfieldoption" datasource="jsaplus">
							insert into tbl_savedforms_fieldoptions(SavedFieldID_FK, FieldOptionLabel, FieldOptionValue)
							values(<cfqueryparam value="#SavedField.GENERATED_KEY#" cfsqltype="cf_sql_integer">,
							<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldOptions'][iii]['Label']#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['FieldOptions'][iii]['Value']#" cfsqltype="cf_sql_varchar">)
							</cfquery>
	
							<cfcatch>
							<!--- we do not stop processing for form save errors --->
							<cfscript>
							ArrayAppend(response.messages, "FormSaveError");
							</cfscript>
							</cfcatch>
							
							</cftry>
							
						</cfloop>
					
					<cfelseif ARGUMENTS.nodeInfo[i][ii]["FieldType"] eq "NumericStepper">
			
						<cftry>
						
						<cfquery name="addsavedsteppersettings" datasource="jsaplus">
							insert into tbl_savedforms_stepper_settings(SavedFieldID_FK,StepSize,Min,Max)
							values(<cfqueryparam value="#SavedField.GENERATED_KEY#" cfsqltype="cf_sql_integer">,
							<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['StepSize']#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['Min']#" cfsqltype="cf_sql_varchar">,
							<cfqueryparam value="#ARGUMENTS.nodeInfo[i][ii]['StepperSettings']['Max']#" cfsqltype="cf_sql_varchar">)
						</cfquery>
			
						<cfcatch>
						<!--- we do not stop processing for form save errors --->
						<cfscript>
						ArrayAppend(response.messages, "FormSaveError");
						</cfscript>
						</cfcatch>
						
						</cftry>
			
					</cfif>
	
				</cfif>
				
			</cfloop>
		
		</cfloop>		
		
	</cfif>
	
	
	<cfreturn response>

</cffunction>


</cfcomponent>