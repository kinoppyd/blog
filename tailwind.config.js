module.exports = {
  content: [
    './_drafts/**/*.html',
    './_includes/**/*.html',
    './_layouts/**/*.html',
    './_posts/*.md',
    './*.md',
    './*.html',
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
