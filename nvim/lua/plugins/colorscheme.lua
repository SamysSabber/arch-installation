return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "moon",
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
      on_highlights = function(hl, c)
        -- Statusline komplett transparent
        hl.StatusLine = { fg = c.fg, bg = "NONE" }
        hl.StatusLineNC = { fg = c.fg_dark, bg = "NONE" }
        hl.WinSeparator = { fg = c.border_highlight, bg = "NONE" }

        -- Lualine sections
        hl.lualine_a_normal = { fg = c.blue, bg = "NONE", bold = true }
        hl.lualine_b_normal = { fg = c.fg, bg = "NONE" }
        hl.lualine_c_normal = { fg = c.fg_dark, bg = "NONE" }
        hl.lualine_x_normal = { fg = c.fg_dark, bg = "NONE" }
        hl.lualine_y_normal = { fg = c.fg, bg = "NONE" }
        hl.lualine_z_normal = { fg = c.blue, bg = "NONE", bold = true }

        -- Andere Modi
        hl.lualine_a_insert = { fg = c.green, bg = "NONE", bold = true }
        hl.lualine_a_visual = { fg = c.magenta, bg = "NONE", bold = true }
        hl.lualine_a_command = { fg = c.yellow, bg = "NONE", bold = true }
      end,
    },
  },
}
