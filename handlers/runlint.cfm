<cfsetting showdebugoutput="false">
<cfscript>
helper = new builderHelper(form.ideEventInfo);
linter = createObject("java","com.cflint.CFLint");

selection = helper.getSelectedResource();
//get the project, this is not currently supported by my helper, may add it in later
projectNode = xmlParse(form.ideEventInfo).event.ide.projectview;
projectName = projectNode.xmlAttributes.projectName;
projectLocation = projectNode.xmlAttributes.projectLocation;

if(selection.type is "file") {
	path = replace(selection.path, projectLocation, "");
	title = "file #path#";
} else if(selection.type is "folder") {
	path = replace(selection.path, projectLocation, "");
	title = "folder #path#";
} else {
	title = "project #projectName#";
}

linter.scan(selection.path);
bugs = linter.getBugs();

//Do some massaging on the bugs to make it easier below
bugStruct = bugs.getBugList();
//this is a struct of issues, convert to one array
bugArr = [];

for(type in bugStruct) {
	for(i=1; i<=arrayLen(bugStruct[type]); i++) {
		bug = bugStruct[type][i];
		newBug = {
			message:bug.getMessage(),
			severity:bug.getSeverity(),
			file:bug.getFilename(),
			displayFile:replace(bug.getFilename(),projectLocation, ""),
			line:bug.getLine(),
			column:bug.getColumn()
		};
		arrayAppend(bugArr, newBug);
	}
}

cbUrl = helper.getCallbackURL();
</cfscript>

<cflog text="run cflint3">
<cfheader name="Content-Type" value="text/xml">
<response showresponse="true">
<ide>
<view id="cflintextension" title="CFLint" />
<body>
<![CDATA[
<!DOCTYPE html>
<html lang="en">
	<head>

<!--- inlined due to bug w/ CFB and link tag --->
<style>
<cfinclude template="bootstrap.min.css">
</style>
<script>
<cfinclude template="jquery-2.1.1.min.js">
</script>

<script>
$(document).ready(function() {
	$("a.openFile").on("click", function(e) {
		e.preventDefault();
		var file = $(this).data("file");
		var line = $(this).data("line");
		var column = $(this).data("col");
		<cfoutput>
		$.get("#helper.getRootURL()#openfile.cfm?file="+encodeURIComponent(file)+"&line="+line+"&col="+column+"&cburl="+encodeURIComponent('#cbURL#'), function(res) {
			//do nothing with it...
		});
		</cfoutput>
	});
});
</script>

	</head>

	<cfoutput>
	<body>
		<div class="container">
		<h2>CFLint for #title#</h2>
		<cfif arrayLen(bugArr) is 0>
			<p><strong>Congrats, no issues found!</strong></p>
		<cfelse>
			<table class="table table-striped table-bordered">
				<thead>
					<tr>
						<td>Message</td>
						<td>File</td>
						<td>Severity</td>
					</tr>
				</thead>
				<tbody>
					<cfloop index="bug" array="#bugArr#">
						<cfset severityClass = "">
						<cfif bug.severity is "WARNING">
							<cfset severityClass = "text-warning">
						<cfelseif bug.severity is "ERROR">
							<cfset severityClass = "text-danger">
						<cfelseif bug.severity is "INFO">
							<cfset severityClass = "text-info">
						</cfif>
						<tr class="#severityClass#">
							<td>#bug.message#</td>
							<td><a href="" class="openFile" data-file="#bug.file#" data-line="#bug.line#" data-col="#bug.column#">#bug.displayFile# (#bug.line#:#bug.column#)</a></td>
							<td>#bug.severity#</td>
					</cfloop>
				</tbody>
			</table>
			<!---
			<p>
			#serializeJSON(bugs)#
			</p>
			--->
		</cfif>
		</div>
	</body>
	</cfoutput>
</html>
]]>
</body>
</ide>
</response>
