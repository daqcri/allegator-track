Rails.application.config.assets.precompile += %w( main/index.css main/index.js main/algorithms.js main/visualize.js main/hash_with_length.js jquery-ui-1.9.2/* )
Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf)$/
Rails.application.config.assets.precompile += %w(sort_both.png sort_asc.png sort_desc.png loading-background.png indicator.gif)