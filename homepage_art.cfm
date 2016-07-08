<!---<cfoutput>
<div>#$.component('body')#</div>
</cfoutput>--->

<cfscript>
//Create a feed bean
feed=$.getBean('content');
feed.loadBy(contentID="9DB6305D-5916-4B76-99413F87F2348E19");
feed.setSortBy('contentID');
feed.setSortDirection('desc');
feedQuery = feed.getKidsQuery();
randomNumber = RandRange(1,feedQuery.recordcount)
</cfscript>

<cfquery name="getRandomImage" dbtype="query">
	select fileID, contentID, fileext from feedquery
	where OrderNo = #randomNumber#
</cfquery>

	<cfif isLocalHost(CGI.REMOTE_ADDR)>
		<cfset path="http://localhost:8080">
	<cfelse>
		<cfset path="http://www.finemarineart.com">
	</cfif>
<cftry>
	<cfimage source="#path##$.siteConfig('AssetPath')#/cache/file/#getRandomImage.fileID#.#getRandomImage.fileext#" name="displayImage" action="border" color="CCC" thickness="1">
	<cfimage source="#path##$.siteConfig('AssetPath')#/assets/logo.png" name="logo">
	<cfset ImagePaste(displayImage,logo,367,25)>
	<cfimage source="#displayImage#" action="writetobrowser">
	<cfcatch><!---<cfdump var="#cfcatch#">---></cfcatch>
</cftry>
<!--- Use this if you want [mura] tags to render.--->
<!---<cfoutput>
<div>#$.setDynamicContent($.component('body'))#</div>

</cfoutput>--->