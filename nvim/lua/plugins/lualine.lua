return {
  "nvim-lualine/lualine.nvim",
  opts = function()
    local colors = require("tokyonight.colors").setup()

    return {
      options = {
        theme = {
          normal = {
            a = { fg = colors.blue, bg = "NONE", gui = "bold" },
            b = { fg = colors.fg, bg = "NONE" },
            c = { fg = colors.fg_dark, bg = "NONE" },
          },
          insert = {
            a = { fg = colors.green, bg = "NONE", gui = "bold" },
            b = { fg = colors.fg, bg = "NONE" },
            c = { fg = colors.fg_dark, bg = "NONE" },
          },
          visual = {
            a = { fg = colors.magenta, bg = "NONE", gui = "bold" },
            b = { fg = colors.fg, bg = "NONE" },
            c = { fg = colors.fg_dark, bg = "NONE" },
          },
          command = {
            a = { fg = colors.yellow, bg = "NONE", gui = "bold" },
            b = { fg = colors.fg, bg = "NONE" },
            c = { fg = colors.fg_dark, bg = "NONE" },
          },
          replace = {
            a = { fg = colors.red, bg = "NONE", gui = "bold" },
            b = { fg = colors.fg, bg = "NONE" },
            c = { fg = colors.fg_dark, bg = "NONE" },
          },
          inactive = {
            a = { fg = colors.fg_dark, bg = "NONE" },
            b = { fg = colors.fg_dark, bg = "NONE" },
            c = { fg = colors.fg_dark, bg = "NONE" },
          },
        },
        component_separators = "",
        section_separators = "",
      },
    }
  end,
}
