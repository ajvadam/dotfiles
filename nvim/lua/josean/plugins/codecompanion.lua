return {
  "olimorris/codecompanion.nvim",
  config = function()
    local default_model = "deepseek/deepseek-chat-v3-0324:free"

    local function select_model()
      vim.notify("DeepSeek model is fixed to: " .. default_model)
    end

    require("codecompanion").setup({
      strategies = {
        chat = { adapter = "openrouter_deepseek" },
        inline = { adapter = "openrouter_deepseek" },
      },
      adapters = {
        openrouter_deepseek = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            env = {
              url = "https://openrouter.ai/api",
              api_key = "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",
              chat_url = "/v1/chat/completions",
            },
            schema = {
              model = { default = default_model },
            },
          })
        end,
      },
      -- Inline assistant configuration
      inline = {
        border = "rounded", -- Style of the floating window
        width = 0.6,        -- 60% of editor width
        height = 0.4,       -- 40% of editor height
        enter = true,       -- Automatically enter insert mode
        focusable = true,   -- Window can be focused
      }
    })

    -- Keymaps
    vim.keymap.set({ "n", "v" }, "<leader>cc", function()
      require("codecompanion").inline()
    end, { desc = "Trigger inline assistant" })

    vim.keymap.set({ "n", "v" }, "<leader>ck", "<cmd>CodeCompanionActions<cr>", { desc = "Code actions" })
    vim.keymap.set({ "n", "v" }, "<leader>a", "<cmd>CodeCompanionChat Toggle<cr>", { desc = "Toggle chat" })
    vim.keymap.set("v", "ga", "<cmd>CodeCompanionChat Add<cr>", { desc = "Add to chat" })
    vim.keymap.set("n", "<leader>cs", select_model, { desc = "Show current model" })

    -- Command abbreviation
    vim.cmd([[cab cc CodeCompanion]])
  end,

  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
}
