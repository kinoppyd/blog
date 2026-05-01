const path = require('path')

const setDefaultFrom = {
  postcssPlugin: 'set-default-from',
  Once(_root, { result }) {
    // jekyll-postcss passes `from: undefined`, which breaks Tailwind v4 module resolution.
    if (!result.opts.from) {
      result.opts.from = path.join(process.cwd(), 'assets/css/main.css')
    }
  },
}

module.exports = {
  plugins: [
    require('postcss-import'),
    setDefaultFrom,
    require('@tailwindcss/postcss'),
    require('autoprefixer'),
    ...(process.env.JEKYLL_ENV == 'production'
      ? [require('cssnano')({ preset: 'default' })]
      : [])
  ]
}
