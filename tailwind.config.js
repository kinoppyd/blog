module.exports = {
  content: [
    './_drafts/**/*.md',
    './_includes/**/*.html',
    './_layouts/**/*.html',
    './_posts/*.md',
    './*.md',
    './*.html',
    './_plugins/*.erb',
  ],
  darkmode: false,
  theme: {
    extend: {
      fontFamily: {
        noto: ['Noto Sans JP', "sans-serif"]
      }
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ]
}
