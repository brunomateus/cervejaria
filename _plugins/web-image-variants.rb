#!/usr/bin/env ruby
#
# Serve versões leves das fotos, mantendo as originais no repositório.
#
# `tools/otimizar-imagens.sh` gera, para cada foto grande, uma variante em
# `assets/img/<pasta>/web/<nome>.jpg`. Este plugin faz essa variante ser a
# imagem que o site publica:
#
# 1. `post_read` remove do build toda original que já tenha variante. Elas
#    continuam versionadas no git (o backup), mas não vão para o `_site` — o
#    que tira centenas de MB do deploy do GitHub Pages.
#
# 2. `post_render` reescreve, na saída final, todo caminho de imagem que aponte
#    para uma original com variante. Agir sobre a saída (e não sobre o markdown)
#    é o que faz isso valer para os três jeitos de referenciar uma foto neste
#    blog: `<img src>` cru, markdown `![](...)` e os posts antigos que combinam
#    `img_path:` no front matter com o nome puro do arquivo. Nenhum post precisa
#    ser editado, e o preview do VS Code continua exibindo a original.
#
# A existência da variante é a única fonte de verdade: sem variante, a original
# é publicada e referenciada normalmente. Por isso um build nunca fica com
# `src` apontando para arquivo ausente.

module Cervejaria
  module WebImageVariants
    VARIANT_DIR = 'web'
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png].freeze

    # Um caminho de imagem em qualquer lugar da saída renderizada. Não está
    # ancorado na aspa de abertura de propósito: quando o caminho já vem com o
    # baseurl (`/cervejaria/assets/img/…`), o prefixo fica fora do match e é
    # preservado intacto na substituição.
    IMAGE_PATH_REGEX = %r{/assets/img/((?:[^"'\s)]+/)?)([^/"'\s)]+)\.(jpe?g|png)}i

    class << self
      # Índice das variantes existentes, por caminho relativo à raiz do site.
      # Reconstruído a cada build para que um `jekyll serve --watch` enxergue
      # variantes geradas com o servidor no ar.
      def reindex(site)
        pattern = File.join(site.source, 'assets', 'img', '**', VARIANT_DIR, '*.jpg')
        @index = Dir.glob(pattern).each_with_object({}) do |abs, index|
          index[abs.delete_prefix("#{site.source}/")] = true
        end
      end

      def index
        @index ||= {}
      end

      # Caminho da variante de `relative_path`, ou nil se não houver variante
      # (ou se o próprio arquivo já for uma variante).
      def variant_for(relative_path)
        path = relative_path.delete_prefix('/')
        return nil unless path.start_with?('assets/img/')
        return nil unless IMAGE_EXTENSIONS.include?(File.extname(path).downcase)

        dir = File.dirname(path)
        return nil if File.basename(dir) == VARIANT_DIR

        candidate = "#{dir}/#{VARIANT_DIR}/#{File.basename(path, '.*')}.jpg"
        index.key?(candidate) ? candidate : nil
      end

      def rewrite(content)
        return content if content.nil? || index.empty?

        content.gsub(IMAGE_PATH_REGEX) do
          whole = Regexp.last_match(0)
          candidate = "assets/img/#{Regexp.last_match(1)}#{VARIANT_DIR}/#{Regexp.last_match(2)}.jpg"
          index.key?(candidate) ? "/#{candidate}" : whole
        end
      end
    end
  end
end

Jekyll::Hooks.register :site, :post_read do |site|
  Cervejaria::WebImageVariants.reindex(site)

  before = site.static_files.size
  site.static_files.reject! do |file|
    Cervejaria::WebImageVariants.variant_for(file.relative_path)
  end
  removed = before - site.static_files.size

  Jekyll.logger.info 'Variantes web:', "#{removed} original(is) mantida(s) fora do site publicado" if removed.positive?
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |item|
  item.output = Cervejaria::WebImageVariants.rewrite(item.output)
end
