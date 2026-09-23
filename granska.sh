#!/usr/bin/env bash
# Mekanisk granskning innan commit. Körs i repots rot.
# Tar det som går att kontrollera med maskin. Resten står i ARBETSMALL avsnitt 6.
#
#   bash granska.sh          granska en del innan commit
#   bash granska.sh --slut   slutgranskning innan push: mallrader räknas som fel
#   bash granska.sh --tyst   bara felen (går att kombinera)
set -u

TYST=0
SLUT=0
for a in "$@"; do
    case "$a" in
        --tyst) TYST=1 ;;
        --slut) SLUT=1 ;;
    esac
done
FEL=0

# ok och rubrik måste ALLTID returnera 0. De används som B i "A && B || C",
# och returnerar de 1 i tyst läge avfyras C, alltså fel, för allt som är rätt.
ok()  { if [ "$TYST" = 0 ]; then printf '  ok    %s\n' "$*"; fi; return 0; }
fel() { printf '  FEL   %s\n' "$*"; FEL=$((FEL+1)); return 0; }
rubrik() { if [ "$TYST" = 0 ]; then printf '\n%s\n' "$*"; fi; return 0; }

# Både spårade filer och nya som ännu inte lagts till, men inte ignorerade.
# Annars går det inte att granska något innan första git add.
TEXTFILER=$(git ls-files --cached --others --exclude-standard 2>/dev/null \
            | grep -E '\.(md|tf|tfvars\.exempel|yaml|yml|tftpl|sh|txt)$' | sort -u || true)
[ -z "$TEXTFILER" ] && { echo "inga textfiler i git, står jag i repots rot?"; exit 1; }

# --------------------------------------------------------------- språk ----
rubrik "Språk"

# ASCII-svenska: vanliga ord som tappat å, ä eller ö. Mappnamn undantas.
MONSTER='\b(natverk|granssnitt|forsta|installning|maste|sokvag|behover|nagot|hander|lamnar|dopper|anvand|sjalv|tva|fran|ocksa|nagon|forklar|andra inte|for hand|pa ett|ar inte)\b'
TRAFF=$(echo "$TEXTFILER" | grep -v "granska.sh" | xargs grep -nE "$MONSTER" 2>/dev/null | grep -viE 'natverksdokumentation|arbetsmall' || true)
if [ -n "$TRAFF" ]; then
    fel "ASCII-svenska (ord utan å ä ö):"
    echo "$TRAFF" | head -15 | sed 's/^/          /'
else
    ok "ingen ASCII-svenska"
fi

# Tecknet byggs ur sina byte så att skriptet inte flaggar sig självt.
TANKSTRECK=$(printf '\xe2\x80\x94')
TRAFF=$(echo "$TEXTFILER" | xargs grep -n "$TANKSTRECK" 2>/dev/null || true)
if [ -n "$TRAFF" ]; then
    fel "tankstreck:"
    echo "$TRAFF" | head -10 | sed 's/^/          /'
else
    ok "inga tankstreck"
fi

# --------------------------------------------------------------- dokument -
rubrik "Dokument"

for f in $(echo "$TEXTFILER" | grep '\.md$'); do
    T=$(grep -nE 'TODO|FIXME|XXX' "$f" || true)
    [ -n "$T" ] && { fel "$f har TODO:"; echo "$T" | head -5 | sed 's/^/          /'; }
    # Instruktionsrader från mallen börjar med "> (mall)". Vanliga citat med
    # bara ">" är tillåtna, de används för prompt och svar i AI-loggen.
    # Under arbetet har ogjorda delar kvar sina mallrader, så de är bara en
    # upplysning. Vid slutgranskningen (--slut) är varje kvarvarande rad ett fel.
    ANTAL=$(grep -c '^> (mall)' "$f" || true)
    if [ "${ANTAL:-0}" -gt 0 ]; then
        if [ "$SLUT" = 1 ]; then
            fel "$f har $ANTAL mallrader kvar:"
            grep -n '^> (mall)' "$f" | head -5 | sed 's/^/          /'
        else
            [ "$TYST" = 0 ] && printf '  info  %s: %s mallrader kvar i delar som inte är klara\n' "$f" "$ANTAL"
        fi
    fi
done
[ "$FEL" = 0 ] && ok "inga TODO eller instruktionsrader"

# Bildlänkar
for f in $(echo "$TEXTFILER" | grep '\.md$'); do
    for bild in $(grep -v '^> (mall)' "$f" | grep -oE '!\[[^]]*\]\([^)]+\)' | sed 's/.*(//; s/)//' || true); do
        [ -f "$bild" ] && ok "bild finns: $bild" || fel "$f länkar till bild som saknas: $bild"
    done
done

# Rubriknumrering: ## N. ska vara löpande
for f in $(echo "$TEXTFILER" | grep '\.md$'); do
    NUM=$(grep -oE '^## [0-9]+\.' "$f" | grep -oE '[0-9]+' || true)
    [ -z "$NUM" ] && continue
    VANTAT=1; BRUTEN=0
    for n in $NUM; do
        [ "$n" != "$VANTAT" ] && BRUTEN=1
        VANTAT=$((n+1))
    done
    [ "$BRUTEN" = 1 ] && fel "$f: huvudrubrikerna är inte löpande numrerade" || ok "$f: rubriker löpande"
done

# ---------------------------------------------------------------- terraform
if [ -d terraform ]; then
    rubrik "Terraform"
    if command -v terraform >/dev/null 2>&1; then
        (cd terraform && terraform fmt -check >/dev/null 2>&1) && ok "fmt" || fel "terraform fmt -check klagar"
        (cd terraform && terraform validate >/dev/null 2>&1) && ok "validate" || fel "terraform validate klagar"
    else
        ok "terraform inte installerat här, hoppar fmt och validate"
    fi
    for v in $(grep -hoE '^variable "[a-z_]+"' terraform/*.tf 2>/dev/null | cut -d'"' -f2); do
        n=$(grep -h "var\.$v\b" terraform/*.tf 2>/dev/null | grep -vc "^variable" || true)
        [ "${n:-0}" -gt 0 ] && ok "variabel används: $v" || fel "variabel deklarerad men aldrig använd: $v"
    done
    # Hemligheter ignorerade?
    for h in terraform/terraform.tfvars; do
        [ -e "$h" ] || continue
        git check-ignore -q "$h" && ok "ignorerad: $h" || fel "INTE ignorerad: $h"
    done
fi

# --------------------------------------------------------------- skript ---
SKRIPT=$(echo "$TEXTFILER" | grep '\.sh$' || true)
if [ -n "$SKRIPT" ]; then
    rubrik "Skript"
    for s in $SKRIPT; do
        bash -n "$s" 2>/dev/null && ok "syntax: $s" || fel "syntaxfel: $s"
    done
fi

# ------------------------------------------------------------- hemligheter
rubrik "Hemligheter i det som skulle committas"
H=$(git grep -nE 'AAAA[A-Za-z0-9+/]{40,}|ghp_[A-Za-z0-9]{20,}|PVEAPIToken=|password\s*=\s*"[^"]{4,}' -- ':!*.md' 2>/dev/null || true)
if [ -n "$H" ]; then
    fel "ser ut som hemlighet eller nyckel i spårad fil:"
    echo "$H" | cut -c1-100 | head -5 | sed 's/^/          /'
else
    ok "inga nycklar eller tokens i spårade filer (md undantaget)"
fi

# ---------------------------------------------------------------- git ----
rubrik "Git"
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
    [ "$TYST" = 0 ] && printf '  info  ocommittade ändringar finns (väntat innan commit)\n'
else
    ok "arbetskatalogen ren"
fi
# Variabelnamn måste vara ASCII, bash tillåter inte å ä ö i dem.
DALIGA=$(git log --pretty=format:'%s' 2>/dev/null | grep -iE '^(fix|wip|uppdatering|ändringar|test|rättelse)\b' || true)
[ -n "$DALIGA" ] && { fel "commit-meddelanden som bryter mot mallen:"; echo "$DALIGA" | sed 's/^/          /'; } || ok "commit-meddelanden följer mallen"
# awk räknar byte, inte tecken, så å ä ö räknas dubbelt. 60 tecken svenska
# kan bli upp mot 70 byte. Gränsen sätts därför i byte med marginal.
FOR_LANGA=$(git log --pretty=format:'%s' 2>/dev/null | awk 'length > 72' || true)
[ -n "$FOR_LANGA" ] && { fel "ämnesrader över 60 tecken:"; echo "$FOR_LANGA" | sed 's/^/          /'; } || ok "ämnesrader inom 60 tecken"

# ------------------------------------------------------------- resultat --
echo
if [ "$FEL" = 0 ]; then
    echo "GRÖNT. Klart att committa, förutsatt att den manuella delen av checklistan är gjord."
    exit 0
else
    echo "RÖTT: $FEL fel. Rätta i arbetskopian, committa inte."
    exit 1
fi
