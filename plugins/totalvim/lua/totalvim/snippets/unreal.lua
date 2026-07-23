-- UE5-snippets for C++. <C-j> bytter specifier-varianter (choice-noder).
-- API-kunnskapen selv kommer fra clangd som indekserer engine-headerne
-- (:UnrealGenerateClangDB) — snippets dekker boilerplate-mønstrene rundt.
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

ls.add_snippets("cpp", {

  -- Klasse-skjeletter --------------------------------------------------------

  s({ trig = "uactor", dscr = "AActor-subklasse (header). Spawnbar i level.\nEksempel: class MYGAME_API AMyActor : public AActor" },
    fmt([[
UCLASS({})
class {} A{} : public AActor
{{
	GENERATED_BODY()

public:
	A{}();

protected:
	virtual void BeginPlay() override;

public:
	virtual void Tick(float DeltaTime) override;
	{}
}};
]], { ch(1, { "", "Blueprintable", "Blueprintable, BlueprintType" }), i(2, "MYGAME_API"), i(3, "MyActor"), rep(3), i(0) })),

  s({ trig = "ucomp", dscr = "UActorComponent-subklasse, spawnbar fra Blueprint (BlueprintSpawnableComponent)." },
    fmt([[
UCLASS(ClassGroup=({}), meta=(BlueprintSpawnableComponent))
class {} U{} : public UActorComponent
{{
	GENERATED_BODY()

public:
	U{}();

protected:
	virtual void BeginPlay() override;

public:
	virtual void TickComponent(float DeltaTime, ELevelTick TickType, FActorComponentTickFunction* ThisTickFunction) override;
	{}
}};
]], { i(1, "Custom"), i(2, "MYGAME_API"), i(3, "MyComponent"), rep(3), i(0) })),

  s({ trig = "uobj", dscr = "UObject-subklasse (BlueprintType). For ren data/logikk uten transform." },
    fmt([[
UCLASS(BlueprintType)
class {} U{} : public UObject
{{
	GENERATED_BODY()

public:
	{}
}};
]], { i(1, "MYGAME_API"), i(2, "MyObject"), i(0) })),

  s({ trig = "ustruct", dscr = "USTRUCT(BlueprintType) med eksempel-UPROPERTY. F-prefiks påkrevd." },
    fmt([[
USTRUCT(BlueprintType)
struct F{}
{{
	GENERATED_BODY()

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "{}")
	{} {} = {};
}};
]], { i(1, "MyStruct"), i(2, "Data"), i(3, "float"), i(4, "Value"), i(5, "0.f") })),

  s({ trig = "uenum", dscr = "UENUM(BlueprintType) enum class : uint8 (uint8 er krav for Blueprint)." },
    fmt([[
UENUM(BlueprintType)
enum class E{} : uint8
{{
	{} UMETA(DisplayName = "{}"),
	{}
}};
]], { i(1, "MyEnum"), i(2, "None"), rep(2), i(0) })),

  s({ trig = "uinterface", dscr = "UINTERFACE-par: U-klassen er UObject-limet, I-klassen er API-et du arver fra." },
    fmt([[
UINTERFACE(MinimalAPI, Blueprintable)
class U{} : public UInterface
{{
	GENERATED_BODY()
}};

class I{}
{{
	GENERATED_BODY()

public:
	UFUNCTION(BlueprintCallable, BlueprintNativeEvent, Category = "{}")
	{};
}};
]], { i(1, "MyInterface"), rep(1), i(2, "Interface"), i(3, "void DoThing()") })),

  -- Properties ---------------------------------------------------------------

  s({ trig = "uprop", dscr = table.concat({
    "UPROPERTY — <C-j> bytter specifier-sett:",
    "EditAnywhere, BlueprintReadWrite  = redigerbar overalt + BP les/skriv",
    "VisibleAnywhere, BlueprintReadOnly = synlig, ikke redigerbar",
    "EditDefaultsOnly, BlueprintReadOnly = kun i BP-defaults",
    "Replicated = nettverk (krever GetLifetimeReplicatedProps)",
  }, "\n") },
    fmt([[
UPROPERTY({}, Category = "{}")
{} {};
]], { ch(1, {
        "EditAnywhere, BlueprintReadWrite",
        "VisibleAnywhere, BlueprintReadOnly",
        "EditDefaultsOnly, BlueprintReadOnly",
        "EditAnywhere",
        "Replicated, EditAnywhere, BlueprintReadWrite",
      }), i(2, "Gameplay"), i(3, "float"), i(4, "Value") })),

  s({ trig = "upropc", dscr = "Komponent-peker: TObjectPtr er UE5-standard for UPROPERTY-pekere." },
    fmt([[
UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Components")
TObjectPtr<{}> {};
]], { i(1, "UStaticMeshComponent"), i(2, "Mesh") })),

  s({ trig = "utsub", dscr = "TSubclassOf-property: klassevelger i editor, brukes med SpawnActor." },
    fmt([[
UPROPERTY(EditDefaultsOnly, Category = "{}")
TSubclassOf<{}> {};
]], { i(1, "Spawning"), i(2, "AActor"), i(3, "ActorClass") })),

  -- Funksjoner ---------------------------------------------------------------

  s({ trig = "ufunc", dscr = "UFUNCTION — <C-j> bytter:\nBlueprintCallable = kallbar fra BP\nBlueprintPure = ingen exec-pin, kun retur\nCallInEditor = knapp i details-panelet" },
    fmt([[
UFUNCTION({}, Category = "{}")
{} {}({});
]], { ch(1, { "BlueprintCallable", "BlueprintPure", "BlueprintCallable, CallInEditor" }), i(2, "Gameplay"), i(3, "void"), i(4, "DoThing"), i(5) })),

  s({ trig = "ubpevent", dscr = "BlueprintImplementableEvent = kun BP-implementasjon.\nBlueprintNativeEvent = C++-default (_Implementation i .cpp) + BP-override." },
    fmt([[
UFUNCTION({}, Category = "{}")
{} {}({});
]], { ch(1, { "BlueprintImplementableEvent", "BlueprintCallable, BlueprintNativeEvent" }), i(2, "Events"), i(3, "void"), i(4, "OnThing"), i(5) })),

  s({ trig = "urpc", dscr = "RPC — <C-j> bytter:\nServer = klient→server, Client = server→eier-klient, NetMulticast = server→alle.\n_Implementation kreves i .cpp." },
    fmt([[
UFUNCTION({}, Reliable{})
void {}({});
]], { ch(1, { "Server", "Client", "NetMulticast" }), ch(2, { "", ", WithValidation" }), i(3, "ServerDoThing"), i(4) })),

  s({ trig = "udelegate", dscr = "Dynamic multicast delegate, BP-bindbar via BlueprintAssignable.\n_OneParam/_TwoParams tar Type, Name-par etter delegatnavnet." },
    fmt([[
DECLARE_DYNAMIC_MULTICAST_DELEGATE{}(F{}{});

UPROPERTY(BlueprintAssignable, Category = "Events")
F{} {};
]], { ch(1, { "", "_OneParam", "_TwoParams" }), i(2, "OnThingHappened"), i(3), rep(2), i(4, "OnThingHappened") })),

  -- Vanlige mønstre ----------------------------------------------------------

  s({ trig = "ulog", dscr = "UE_LOG. Verbosity: Warning/Log/Error/Display/Verbose.\nTEXT() påkrevd. %s krever *FString, ellers %d/%f/%hs." },
    fmt([[UE_LOG(LogTemp, {}, TEXT("{}"){});]],
      { ch(1, { "Warning", "Log", "Error", "Display", "Verbose" }), i(2, "%s"), i(3, ", *GetName()") })),

  s({ trig = "ucast", dscr = "Cast<T> med nullsjekk i if-init. Returnerer nullptr ved feil type." },
    fmt([[
if ({}* {} = Cast<{}>({}))
{{
	{}
}}
]], { i(1, "AMyActor"), i(2, "Actor"), rep(1), i(3, "OtherActor"), i(0) })),

  s({ trig = "uspawn", dscr = "SpawnActor fra TSubclassOf: klasse, location, rotation." },
    fmt([[{}* {} = GetWorld()->SpawnActor<{}>({}, {}, {});]],
      { i(1, "AMyActor"), i(2, "Spawned"), rep(1), i(3, "ActorClass"), i(4, "GetActorLocation()"), i(5, "FRotator::ZeroRotator") })),

  s({ trig = "utimer", dscr = "SetTimer: handle (FTimerHandle-medlem), callback, rate i sekunder, loop." },
    fmt([[GetWorldTimerManager().SetTimer({}, this, &{}::{}, {}, {});]],
      { i(1, "TimerHandle"), i(2, "AMyActor"), i(3, "OnTimer"), i(4, "1.0f"), ch(5, { "true", "false" }) })),

  s({ trig = "uinput", dscr = "Enhanced Input-bind i SetupPlayerInputComponent.\nETriggerEvent: Triggered (hver frame), Started (én gang), Completed (slipp)." },
    fmt([[EnhancedInputComponent->BindAction({}, ETriggerEvent::{}, this, &{}::{});]],
      { i(1, "MoveAction"), ch(2, { "Triggered", "Started", "Completed" }), i(3, "AMyActor"), i(4, "Move") })),
})
