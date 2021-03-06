--dir names
SCEN_EDIT_DIR = "scen_edit/"
LIBS_DIR = "libs/"
SCEN_EDIT_COMMAND_DIR = SCEN_EDIT_DIR .. "command/"
LUAUI_DIR = "LuaUI/"
SCEN_EDIT_IMG_DIR = LUAUI_DIR .. "images/scenedit/"
--FIXME: don't assume path, find it programatically
--FIXME: not used now
-- SCENARIO_EDITOR_DIR = "games/ToolBox.sdd/"
SCEN_EDIT_EXAMPLE_DIR_RAW_FS = "projects/" -- SCENARIO_EDITOR_DIR .. "examples/"

--properties
SCEN_EDIT_FILE_EXT = ".sdz"
SCEN_EDIT_FEATURE_PLACER_FILE_EXT = ".lua"

--mod opts
local modOpts = Spring.GetModOptions()

SCEN_EDIT.projectDir = modOpts.project_dir
devMode = (tonumber(modOpts.play_mode) or 0) == 0
if devMode then
    Spring.Echo("Scenario Editor mode: dev")
else
    Spring.Echo("Scenario Editor mode: play")
end
hasScenarioFile = (tonumber(modOpts.has_scenario_file) or 0) ~= 0

--chili export
if WG and WG.Chili then
    -- setup Chili
    Chili = WG.Chili
    Checkbox = Chili.Checkbox
    Control = Chili.Control
    ComboBox = Chili.ComboBox
    Colorbars = Chili.Colorbars
    Button = Chili.Button
    Label = Chili.Label
    Line = Chili.Line
    EditBox = Chili.EditBox
    Window = Chili.Window
    ScrollPanel = Chili.ScrollPanel
    LayoutPanel = Chili.LayoutPanel
    StackPanel = Chili.StackPanel
    Grid = Chili.Grid
    TextBox = Chili.TextBox
    Image = Chili.Image
    ImageListView = Chili.ImageListView
    TreeView = Chili.TreeView
    Trackbar = Chili.Trackbar
	TabBar = Chili.TabBar
	TabPanel = Chili.TabPanel
    screen0 = Chili.Screen0
end
