<cfsetting showdebugoutput="false">

<cfsavecontent variable="commandxml" > 
<cfoutput> 
    <response> 
        <ide> 
		<commands> 
			<command type="openFile"> 
			<params> 
				<cfoutput>
				<param key="filename" value="#url.file#" /> 
				<param key="linenumber" value="#url.line#" /> 
				</cfoutput>
			</params> 
			</command> 
		</commands>     
        </ide> 
    </response> 
</cfoutput> 
</cfsavecontent>

<cflog text="command xml? #commandxml#">

<cfhttp method="post" url="#url.cburl#" result="commandresponse" > 
    <cfhttpparam type="body" value="#commandxml#" > 
</cfhttp>