-- Bevy-snippets for Rust. <C-j> bytter varianter (choice-noder).
-- API-kunnskapen selv kommer fra rust-analyzer som indekserer cargo-dep-treet —
-- snippets dekker ECS-boilerplate-mønstrene rundt.
local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local c = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

local function ch(idx, options)
  return c(idx, vim.tbl_map(t, options))
end

ls.add_snippets("rust", {

  -- App-skjeletter -----------------------------------------------------------

  s({ trig = "bmain", dscr = "main.rs App-skjelett: DefaultPlugins + Startup/Update-systemer." },
    fmt([[
use bevy::prelude::*;

fn main() {{
    App::new()
        .add_plugins(DefaultPlugins)
        .add_systems(Startup, {})
        .add_systems(Update, {})
        .run();
}}
]], { i(1, "setup"), i(2) })),

  s({ trig = "bplugin", dscr = "Plugin-struct + impl Plugin. Registrer med app.add_plugins(MyPlugin)." },
    fmt([[
pub struct {}Plugin;

impl Plugin for {}Plugin {{
    fn build(&self, app: &mut App) {{
        app.add_systems(Update, {});
    }}
}}
]], { i(1, "My"), rep(1), i(2) })),

  -- ECS-typer ----------------------------------------------------------------

  s({ trig = "bcomp", dscr = "Component med felter. <C-j> bytter ekstra derives.\n#[require(Transform)] over structen auto-legger required components (0.15+)." },
    fmt([[
#[derive(Component{})]
struct {} {{
    {}
}}
]], { ch(1, { "", ", Debug", ", Debug, Default" }), i(2, "MyComponent"), i(3, "value: f32,") })),

  s({ trig = "bmark", dscr = "Marker-component (unit struct). Brukes som Query-filter: With<Marker>." },
    fmt([[
#[derive(Component)]
struct {};
]], { i(1, "Player") })),

  s({ trig = "bres", dscr = "Resource. Registrer: app.init_resource::<T>() (krever Default) eller .insert_resource(T {...}).\nLes i system: Res<T> / ResMut<T>." },
    fmt([[
#[derive(Resource{})]
struct {} {{
    {}
}}
]], { ch(1, { ", Default", "" }), i(2, "MyResource"), i(3, "value: f32,") })),

  s({ trig = "bevent", dscr = "Event. Registrer: app.add_event::<T>(). Les/skriv: EventReader/EventWriter.\n(Bevy 0.17+: bufrede events heter Message med MessageReader/MessageWriter.)" },
    fmt([[
#[derive(Event{})]
struct {} {{
    {}
}}
]], { ch(1, { "", ", Debug" }), i(2, "MyEvent"), i(3) })),

  s({ trig = "bstate", dscr = "States-enum. Registrer: app.init_state::<T>().\nBruk: run_if(in_state(T::X)), add_systems(OnEnter(T::X), ...), OnExit." },
    fmt([[
#[derive(States, Debug, Clone, PartialEq, Eq, Hash, Default)]
enum {} {{
    #[default]
    {},
    {}
}}
]], { i(1, "GameState"), i(2, "Menu"), i(3, "InGame") })),

  -- Systemer -----------------------------------------------------------------

  s({ trig = "bsys", dscr = table.concat({
    "System-fn. Vanlige params:",
    "mut commands: Commands",
    "query: Query<&mut Transform, With<Player>>",
    "time: Res<Time>  /  mut res: ResMut<MyResource>",
    "mut events: EventReader<MyEvent> / EventWriter<MyEvent>",
    "single: Single<&Transform, With<Camera>>",
  }, "\n") },
    fmt([[
fn {}({}) {{
    {}
}}
]], { i(1, "my_system"), i(2, "mut commands: Commands"), i(0) })),

  s({ trig = "bsetup", dscr = "Setup-system med kamera. <C-j> bytter Camera2d/Camera3d og ekstra params (assets/meshes)." },
    fmt([[
fn setup(mut commands: Commands{}) {{
    commands.spawn({});
    {}
}}
]], { ch(1, {
        "",
        ", asset_server: Res<AssetServer>",
        ", mut meshes: ResMut<Assets<Mesh>>, mut materials: ResMut<Assets<StandardMaterial>>",
      }), ch(2, { "Camera2d", "Camera3d::default()" }), i(0) })),

  s({ trig = "bquery", dscr = "Query-loop. &query = immutable, &mut query = krever Query<&mut T>.\nFiltre: With<T>, Without<T>, Changed<T>, Added<T>." },
    fmt([[
for {} in {}{} {{
    {}
}}
]], { i(1, "transform"), ch(2, { "&", "&mut " }), i(3, "query"), i(0) })),

  s({ trig = "bspawn", dscr = "Spawn entity med bundle-tuple. Required components (0.15+) legges til automatisk.\n.insert(...) for flere, .id() for Entity, .with_children(...) for hierarki." },
    fmt([[
commands.spawn((
    {},
    Transform::from_xyz({}, {}, {}),
));
]], { i(1, "Sprite::default()"), i(2, "0.0"), i(3, "0.0"), i(4, "0.0") })),

  -- Events / observers -------------------------------------------------------

  s({ trig = "bevr", dscr = "EventReader-loop. Param: mut events: EventReader<MyEvent>.\n(Bevy 0.17+: MessageReader.)" },
    fmt([[
for {} in {}.read() {{
    {}
}}
]], { i(1, "event"), i(2, "events"), i(0) })),

  s({ trig = "bevw", dscr = "EventWriter-send. Param: mut events: EventWriter<MyEvent>.\n(Før 0.16: .send(). Bevy 0.17+: MessageWriter.)" },
    fmt([[{}.write({});]], { i(1, "events"), i(2, "MyEvent") })),

  s({ trig = "bobs", dscr = "Observer-fn. Trigger<OnAdd, T> / Trigger<OnRemove, T> for lifecycle, Trigger<MyEvent> for custom.\nRegistrer: app.add_observer(fn) eller entity.observe(fn). trigger.entity() gir target." },
    fmt([[
fn {}(trigger: Trigger<{}>{}) {{
    {}
}}
]], { i(1, "on_add"), i(2, "OnAdd, MyComponent"), i(3), i(0) })),

  -- Vanlige mønstre ----------------------------------------------------------

  s({ trig = "btimer", dscr = "Timer-tick. Krever time: Res<Time>.\nTimer::from_seconds(1.0, TimerMode::Repeating | TimerMode::Once), ofte i #[derive(Resource)] struct MyTimer(Timer)." },
    fmt([[
if {}.tick(time.delta()).just_finished() {{
    {}
}}
]], { i(1, "timer.0"), i(0) })),

  s({ trig = "bcond", dscr = "Run condition. Alternativer: in_state(...), resource_exists::<T>, on_event::<E>(),\nany_with_component::<T>. Kombiner med .and(...) / .or(...)." },
    fmt([[.add_systems(Update, {}.run_if({}))]],
      { i(1, "my_system"), i(2, "in_state(GameState::InGame)") })),
})
