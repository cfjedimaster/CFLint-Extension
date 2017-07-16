// this is the Application.cfc component
/**
*@hint "this defines the application name and the path to load cflint from"
*/
component {
	this.name = "cflint2";
	this.javaSettings = {"loadPaths":[getDirectoryFromPath(getCurrentTemplatePath()) & "./cflint_lib"]};
}
