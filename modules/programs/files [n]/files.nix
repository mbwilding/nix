{ ... }:

{
  flake.modules.homeManager.files =
    { ... }:

    {
      home = {
        file.".gdbinit".text = ''
          set breakpoint pending on
          set disassembly-flavor intel
        '';

        file.".editorconfig".text = ''
          root = true

          [*]
          charset = utf-8
          end_of_line = lf
          insert_final_newline = true
          trim_trailing_whitespace = true
          indent_style = space
          tab_width = 4
          indent_size = 4
          quote_type = double

          [*.{ts,tsx,js,css,scss,html}]
          quote_type = single

          [*.{yaml,yml,nix}]
          tab_width = 2
          indent_size = 2

          [*.{c++,cc,cpp,cxx,h,h++,hh,hpp,hxx,inl,ipp,tlh,tli}]
          cpp_indent_case_contents_when_block = true
          cpp_new_line_before_open_brace_namespace = same_line[*.{cs,vb}]
          cpp_space_remove_before_semicolon = true

          csharp_indent_labels = one_less_than_current
          csharp_using_directive_placement = outside_namespace:silent
          csharp_prefer_simple_using_statement = true:suggestion
          csharp_prefer_braces = true
          csharp_style_namespace_declarations = file_scoped:suggestion
          csharp_style_expression_bodied_methods = false:silent
          csharp_style_expression_bodied_constructors = false:silent
          csharp_style_expression_bodied_operators = false:silent
          csharp_style_expression_bodied_properties = true:silent
          csharp_style_expression_bodied_indexers = true:silent
          csharp_style_expression_bodied_accessors = true:silent
          csharp_style_expression_bodied_lambdas = true:silent
          csharp_style_expression_bodied_local_functions = false:silent
          csharp_style_throw_expression = true:suggestion
          csharp_style_prefer_null_check_over_type_check = true:suggestion
          csharp_prefer_simple_default_expression = true:suggestion
          csharp_style_prefer_local_over_anonymous_function = true:suggestion
          csharp_style_prefer_index_operator = true:suggestion
          csharp_style_prefer_switch_expression = true:suggestion
          csharp_space_around_binary_operators = before_and_after
          csharp_style_prefer_range_operator = true:suggestion
          csharp_style_implicit_object_creation_when_type_is_apparent = true:suggestion
          csharp_style_prefer_tuple_swap = true:suggestion
          csharp_style_inlined_variable_declaration = true:suggestion
          csharp_style_deconstructed_variable_declaration = true:suggestion
          csharp_style_unused_value_assignment_preference = discard_variable:none
          csharp_style_unused_value_expression_statement_preference = discard_variable:none
          csharp_prefer_static_local_function = true:suggestion
          csharp_style_allow_embedded_statements_on_same_line_experimental = true:silent
          csharp_style_allow_blank_lines_between_consecutive_braces_experimental = true:silent
          csharp_style_allow_blank_line_after_colon_in_constructor_initializer_experimental = true:silent
          csharp_style_conditional_delegate_call = true:suggestion
          csharp_style_prefer_pattern_matching = true:silent
          csharp_style_pattern_matching_over_is_with_cast_check = true:suggestion
          csharp_style_pattern_matching_over_as_with_null_check = true:suggestion
          csharp_style_prefer_not_pattern = true:suggestion
          csharp_style_prefer_extended_property_pattern = true:suggestion
          csharp_style_var_elsewhere = true:none
          csharp_style_var_for_built_in_types = true:none
          csharp_style_var_when_type_is_apparent = true:none
          csharp_style_prefer_method_group_conversion = true:silent
          csharp_style_prefer_top_level_statements = true:silent
          csharp_style_prefer_primary_constructors = false:silent
          csharp_style_prefer_utf8_string_literals = true:suggestion
          csharp_style_prefer_readonly_struct = true:suggestion
          csharp_style_prefer_readonly_struct_member = true:suggestion
          csharp_style_allow_blank_line_after_token_in_conditional_expression_experimental = true:silent
          csharp_style_allow_blank_line_after_token_in_arrow_expression_clause_experimental = true:silent
          dotnet_analyzer_diagnostic.category-Style.severity = none

          # CA1036: Class should define operators(s) '==, !=, <, <=, >, >=' since it implements IComparable
          dotnet_diagnostic.CA1036.severity = none

          # CA1050: Declare types in namespaces
          dotnet_diagnostic.CA1050.severity = none

          # CA1305: The behavior of 'StringBuilder.AppendLine' could vary based on the locale
          dotnet_diagnostic.CA1305.severity = none

          # CA1848: For improved performance, use the LoggerMessage delegates instead of calling 'LoggerExtensions.Log*'
          dotnet_diagnostic.CA1848.severity = none

          # CS8618: Non-nullable field is uninitialized. Consider declaring as nullable.
          dotnet_diagnostic.CS8618.severity = none

          #### Naming styles ####

          # Naming rules

          dotnet_naming_rule.interface_should_be_begins_with_i.severity = suggestion
          dotnet_naming_rule.interface_should_be_begins_with_i.symbols = interface
          dotnet_naming_rule.interface_should_be_begins_with_i.style = begins_with_i

          dotnet_naming_rule.types_should_be_pascal_case.severity = suggestion
          dotnet_naming_rule.types_should_be_pascal_case.symbols = types
          dotnet_naming_rule.types_should_be_pascal_case.style = pascal_case

          dotnet_naming_rule.non_field_members_should_be_pascal_case.severity = suggestion
          dotnet_naming_rule.non_field_members_should_be_pascal_case.symbols = non_field_members
          dotnet_naming_rule.non_field_members_should_be_pascal_case.style = pascal_case

          # Symbol specifications

          dotnet_naming_symbols.interface.applicable_kinds = interface
          dotnet_naming_symbols.interface.applicable_accessibilities = public, internal, private, protected, protected_internal, private_protected
          dotnet_naming_symbols.interface.required_modifiers = ""

          dotnet_naming_symbols.types.applicable_kinds = class, struct, interface, enum
          dotnet_naming_symbols.types.applicable_accessibilities = public, internal, private, protected, protected_internal, private_protected
          dotnet_naming_symbols.types.required_modifiers = ""

          dotnet_naming_symbols.non_field_members.applicable_kinds = property, event, method
          dotnet_naming_symbols.non_field_members.applicable_accessibilities = public, internal, private, protected, protected_internal, private_protected
          dotnet_naming_symbols.non_field_members.required_modifiers = ""

          # Naming styles

          dotnet_naming_style.begins_with_i.required_prefix = I
          dotnet_naming_style.begins_with_i.required_suffix = ""
          dotnet_naming_style.begins_with_i.word_separator = ""
          dotnet_naming_style.begins_with_i.capitalization = pascal_case

          dotnet_naming_style.pascal_case.required_prefix = ""
          dotnet_naming_style.pascal_case.required_suffix = ""
          dotnet_naming_style.pascal_case.word_separator = ""
          dotnet_naming_style.pascal_case.capitalization = pascal_case

          dotnet_naming_style.pascal_case.required_prefix = ""
          dotnet_naming_style.pascal_case.required_suffix = ""
          dotnet_naming_style.pascal_case.word_separator = ""
          dotnet_naming_style.pascal_case.capitalization = pascal_case
          dotnet_style_operator_placement_when_wrapping = beginning_of_line
          dotnet_style_coalesce_expression = true:suggestion
          dotnet_style_null_propagation = true:suggestion
          dotnet_style_prefer_is_null_check_over_reference_equality_method = true:suggestion
          dotnet_style_prefer_auto_properties = true:silent
          dotnet_style_object_initializer = true:suggestion
          dotnet_style_collection_initializer = true:suggestion
          dotnet_style_prefer_simplified_boolean_expressions = true:suggestion
          dotnet_style_prefer_conditional_expression_over_assignment = true:silent
          dotnet_style_prefer_conditional_expression_over_return = true:silent
          dotnet_style_explicit_tuple_names = true:suggestion
          dotnet_style_prefer_inferred_tuple_names = true:suggestion
          dotnet_style_prefer_inferred_anonymous_type_member_names = true:suggestion
          dotnet_style_prefer_compound_assignment = true:suggestion
          dotnet_style_prefer_simplified_interpolation = true:suggestion
          dotnet_style_namespace_match_folder = true:suggestion
          dotnet_style_readonly_field = true:suggestion
          dotnet_style_predefined_type_for_locals_parameters_members = true:silent
          dotnet_style_predefined_type_for_member_access = true:silent
          dotnet_style_require_accessibility_modifiers = for_non_interface_members:silent
          dotnet_style_allow_multiple_blank_lines_experimental = false:warning
          dotnet_style_allow_statement_immediately_after_block_experimental = true:silent
          dotnet_code_quality_unused_parameters = all:suggestion
          dotnet_style_parentheses_in_arithmetic_binary_operators = always_for_clarity:silent
          dotnet_style_parentheses_in_other_binary_operators = always_for_clarity:silent
          dotnet_style_parentheses_in_relational_binary_operators = always_for_clarity:silent
          dotnet_style_parentheses_in_other_operators = never_if_unnecessary:silent
          dotnet_style_qualification_for_field = false:silent
          dotnet_style_qualification_for_property = false:silent
          dotnet_style_qualification_for_method = false:silent
          dotnet_style_qualification_for_event = false:silent
          dotnet_style_prefer_collection_expression = when_types_loosely_match:suggestion
        '';

        file.".ideavimrc".text = ''
          "" Install plug-ins: IdeaVim, AceJump, IdeaVim-EasyMotion, IdeaVim-Sneak

          let mapleader=" "
          noremap ; :
          set scrolloff=3
          set incsearch
          set hlsearch
          set number
          " set relativenumber
          " set visualbell
          set idearefactormode=keep
          set nocursorline

          " Plug "machakann/vim-highlightedyank"
           Plug "tpope/vim-commentary"
          " Plug "easymotion/vim-easymotion"
          Plug "preservim/nerdtree"

          " set sneak
          " set easymotion
          set commentary
          set NERDTree

          " g:EasyMotion_startofline 0

          Plug "machakann/vim-highlightedyank"
          let g:highlightedyank_highlight_duration = "100"
          let g:highlightedyank_highlight_color = "rgba(160, 160, 160, 155)"
          set highlightedyank

          " Windows
          map     -                   :NERDTreeToggle<CR>
          map     <leader>th          <Action>(ActivateTerminalToolWindow)
          map     q                   <Action>(HideActiveWindow)
          map     <leader>wd          <action>(ActivateDebugToolWindow)
          map     Q                   <action>(CloseEditor)
          " map     <S-s>               <Action>(ShowSettings)

          " Actions
          " map     <leader>da          <Action>(VimFindActionIdAction)
          map     <leader>z           <Action>(ToggleZenMode)
          " map     <leader>vd          <Action>(ToggleDistractionFreeMode)
          " map     <leader>vp          <Action>(TogglePresentationMode)
          map     <leader>d           <Action>(Debug)
          map     <leader>r           <Action>(Run)
          map     <leader>s           <Action>(Stop)
          map     <leader><enter>     <Action>(ShowIntentionActions)
          map     <leader>f           <Action>(ReformatCode)
          map     <leader>fn          <Action>(NewFile)
          map     <leader>rn          <Action>(RenameElement)
          map     <leader>/           <Action>(SearchEverywhere)
          map     <leader><leader>    <Action>(GotoFile)
          map     <leader>ss          <Action>(GotoSymbol)
          map     <leader>sc          <Action>(GotoClass)
          map     <leader>sa          <Action>(GotoAction)
          map     <leader>sh          <Action>(GotoSuperMethod)
          map     <leader>sg          <Action>(TextSearchAction)
          map     <leader>sn          <Action>(ShowNavBar)
          map     <leader>sm          <Action>(FileStructurePopup)
          map     <leader>db          <Action>(ToggleLineBreakpoint)
          map     <leader>dt          <Action>(ToggleBreakpointEnabled)
          map     <leader>gp          <Action>(QuickImplementations)
          map     <leader>gd          <Action>(GotoDefinition)
          map     <leader>gD          <Action>(GotoDeclaration)
          map     <leader>gr          <Action>(FindUsages)
          map     <leader>ci          <Action>(ReSharperGotoImplementation)
          map     <leader>em          <Action>(ExtractMethod)

          " Redo
          map     U                   <C-r>

          "map     g                   <Action>(AceAction)
          "map     F                   <Action>(AceTargetAction)
          "map     g                   <Action>(AceLineAction)

          "" Graveyard
          " map     <leader>wa          <Action>(SaveAll)
          " map     <leader>w           <Action>(SaveDocument)
        '';

        file.".stylua".text = ''
          column_width = 120
          line_endings = "Unix"
          indent_type = "Spaces"
          indent_width = 4
          quote_style = "ForceDouble"
        '';

        file.".yamllint".text = ''
          extend: default

          rules:
           line-length: disable
        '';

        file.".vst/yabridge/yabridge.toml".text = ''
          ["*"]
          group = "all"
          editor_force_dnd = true
        '';

        file.".vst3/yabridge/yabridge.toml".text = ''
          ["*"]
          group = "all"
          editor_force_dnd = true
        '';

        file.".clap/yabridge/yabridge.toml".text = ''
          ["*"]
          group = "all"
          editor_force_dnd = true
        '';

        file.".config/spotify-launcher.conf".text = ''
          --enable-features=UseOzonePlatform
          --ozone-platform=wayland
        '';

        file.".config/ecc/ecc.toml".text = ''
          endpoints = ["192.168.11.191", "192.168.11.192"]
        '';
      };
    };
}
