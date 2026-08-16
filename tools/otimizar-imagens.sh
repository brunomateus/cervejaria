#!/usr/bin/env bash
#
# Gera variantes web das fotos dos posts, preservando as originais.
#
# Para cada imagem grande em assets/img/<pasta>/ este script escreve uma versão
# reduzida em assets/img/<pasta>/web/<nome>.jpg. As originais nunca são
# modificadas nem apagadas — elas continuam no git como backup, mas
# _plugins/web-image-variants.rb as mantém fora do site publicado sempre que
# houver uma variante correspondente.
#
# Usa apenas o sips, que já vem no macOS. Rode depois de adicionar fotos novas
# a um post e faça commit das variantes junto com as originais:
#
#   ./tools/otimizar-imagens.sh
#
# Variáveis de ambiente para ajustar o resultado:
#
#   MAX_DIM=1600     lado maior máximo, em pixels
#   QUALITY=80        qualidade JPEG (0-100)
#   MIN_KB=300        só processa originais acima deste tamanho
#   FORCE=1           regera variantes já atualizadas
#
set -euo pipefail

MAX_DIM=${MAX_DIM:-1600}
QUALITY=${QUALITY:-80}
MIN_KB=${MIN_KB:-300}
FORCE=${FORCE:-0}

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IMG_ROOT="$ROOT/assets/img"

if ! command -v sips >/dev/null 2>&1; then
  echo "erro: sips não encontrado (este script depende do macOS)" >&2
  exit 1
fi

if [[ ! -d "$IMG_ROOT" ]]; then
  echo "erro: $IMG_ROOT não existe" >&2
  exit 1
fi

min_bytes=$((MIN_KB * 1024))

generated=0
uptodate=0
skipped_small=0
bytes_before=0
bytes_after=0

# Lado maior da imagem, em pixels. Imprime 0 se o sips não souber ler o arquivo.
maior_lado() {
  local file=$1 w h
  w=$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth:/ {print $2}')
  h=$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight:/ {print $2}')
  [[ -z ${w:-} || -z ${h:-} ]] && { echo 0; return; }
  if ((w > h)); then echo "$w"; else echo "$h"; fi
}

while IFS= read -r -d '' src; do
  size=$(stat -f%z "$src")
  if ((size < min_bytes)); then
    skipped_small=$((skipped_small + 1))
    continue
  fi

  dir=$(dirname "$src")
  base=$(basename "$src")
  dst="$dir/web/${base%.*}.jpg"

  if [[ $FORCE -ne 1 && -f $dst && $dst -nt $src ]]; then
    uptodate=$((uptodate + 1))
    bytes_before=$((bytes_before + size))
    bytes_after=$((bytes_after + $(stat -f%z "$dst")))
    continue
  fi

  mkdir -p "$dir/web"

  # Só reduz quem passa do limite; recomprimir sem -Z evita que o sips
  # amplie (e degrade) uma imagem que já é pequena em pixels.
  lado=$(maior_lado "$src")
  if ((lado > MAX_DIM)); then
    sips -s format jpeg -s formatOptions "$QUALITY" -Z "$MAX_DIM" "$src" --out "$dst" >/dev/null
  else
    sips -s format jpeg -s formatOptions "$QUALITY" "$src" --out "$dst" >/dev/null
  fi

  new_size=$(stat -f%z "$dst")
  bytes_before=$((bytes_before + size))
  bytes_after=$((bytes_after + new_size))
  generated=$((generated + 1))
  printf '  %s  %s → %s\n' \
    "${src#"$ROOT"/}" \
    "$(numfmt --to=iec "$size" 2>/dev/null || echo "${size}B")" \
    "$(numfmt --to=iec "$new_size" 2>/dev/null || echo "${new_size}B")"
done < <(find "$IMG_ROOT" -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
  ! -path '*/web/*' ! -path '*/favicons/*' -print0 | sort -z)

# Variantes cuja original desapareceu (foto renomeada ou removida do repo).
orfas=()
while IFS= read -r -d '' variant; do
  vdir=$(dirname "$(dirname "$variant")")
  vbase=$(basename "${variant%.jpg}")
  found=0
  for ext in jpg jpeg JPG JPEG png PNG; do
    [[ -f "$vdir/$vbase.$ext" ]] && { found=1; break; }
  done
  ((found == 0)) && orfas+=("${variant#"$ROOT"/}")
done < <(find "$IMG_ROOT" -type f -path '*/web/*' -name '*.jpg' -print0)

echo
echo "variantes geradas:      $generated"
echo "já atualizadas:         $uptodate"
echo "ignoradas (< ${MIN_KB}KB):   $skipped_small"
if ((bytes_before > 0)); then
  before_h=$(numfmt --to=iec "$bytes_before" 2>/dev/null || echo "${bytes_before}B")
  after_h=$(numfmt --to=iec "$bytes_after" 2>/dev/null || echo "${bytes_after}B")
  echo "peso servido:           $before_h → $after_h"
fi

if ((${#orfas[@]} > 0)); then
  echo
  echo "aviso: ${#orfas[@]} variante(s) sem original correspondente (apague à mão se a foto saiu do post):"
  printf '  %s\n' "${orfas[@]}"
fi
