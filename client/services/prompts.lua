PromptsAPI = {}

function PromptsAPI:SetupPromptGroup(groupId)

    ----------------- Setup PromptGroup class and add attributes to prompt-----------------
    local GroupsClass = {}
    GroupsClass.PromptGroup = { id = CheckVar(groupId, GetRandomIntInRange(0, 0xffffff)) }
    GroupsClass.tabAmount = 1 -- Initialization with a default value for tabAmount
    ----------------- ----------------- ----------------- ----------------- ----------

    ----------------- PromptGroup Specific APIs below -----------------
    function GroupsClass:ShowGroup(text,option)
        option = option or {}
        option.mode = option.mode or nil
        option.entity = option.entity or false
        if option.mode == 'ambient' then
           Citizen.InvokeNative(0x315C81D760609108,option.entity, 1.5, 2, GroupsClass.tabAmount, self.PromptGroup.id, CreateVarString(10, 'LITERAL_STRING', CheckVar(text, 'Prompt Info')), 0)
        else
        PromptSetActiveGroupThisFrame(
            self.PromptGroup.id,
            CreateVarString(10, 'LITERAL_STRING', CheckVar(text, 'Prompt Info')), GroupsClass.tabAmount, 0)
        end
    end

    function GroupsClass:GetPromptPage() -- returns the tab currently displayed
        if PromptSetActiveGroupThisFrame(self.PromptGroup.id) < 0 then
            return 0
        end
        return PromptSetActiveGroupThisFrame(self.PromptGroup.id)
    end

    function GroupsClass:SetTabAmount(number) -- updates the group tabAmount
        if GroupsClass.tabAmount < number + 1 then
            GroupsClass.tabAmount = number + 1
        end
    end

    -- TODO: Make a distance check and only show the closest registered prompt (Ideally this should DRASTICALLY help reduce resource consumption)
    function GroupsClass:RegisterPrompt(title, button, enabled, visible, pulsing, mode, options, tabIndex)
        ----------------- Setup Prompt class and add attributes to prompt-----------------
        local PromptClass = {}
        PromptClass.Prompt = {}
        PromptClass.tabIndex = tabIndex or 0
        PromptClass.Prompt = PromptRegisterBegin()
        PromptClass.Mode = mode
        ----------------- ----------------- ----------------- ----------------- ----------

        if type(button) == "table" then -- Manages multi-hash or hash alone
            for _, btn in pairs(button) do
                PromptSetControlAction(PromptClass.Prompt, CheckVar(btn, 0x4CC0E2FE))
            end
        else
            PromptSetControlAction(PromptClass.Prompt, CheckVar(button, 0x4CC0E2FE))
        end

        PromptSetText(PromptClass.Prompt, CreateVarString(10, 'LITERAL_STRING', CheckVar(title, 'Title')))
        PromptSetEnabled(PromptClass.Prompt, CheckVar(enabled, true))
        PromptSetVisible(PromptClass.Prompt, CheckVar(visible, true))
        PromptSetGroup(PromptClass.Prompt, self.PromptGroup.id, PromptClass.tabIndex)

        -- Mode-specific treatment
        if mode == 'click' then
            PromptSetStandardMode(PromptClass.Prompt, true)
        elseif mode == 'customhold' then
            Citizen.InvokeNative(0x94073D5CA3F16B7B, PromptClass.Prompt, CheckVar(options and options.holdtime, 3000))
        elseif mode == 'hold' then
             -- Possible hashes SHORT_TIMED_EVENT_MP, SHORT_TIMED_EVENT, MEDIUM_TIMED_EVENT, LONG_TIMED_EVENT, RUSTLING_CALM_TIMING, PLAYER_FOCUS_TIMING, PLAYER_REACTION_TIMING
            Citizen.InvokeNative(0x74C7D7B72ED0D3CF, PromptClass.Prompt,
                CheckVar(options and options.timedeventhash, 'MEDIUM_TIMED_EVENT'))
        elseif mode == 'mash' then
            Citizen.InvokeNative(0xDF6423BF071C7F71, PromptClass.Prompt, CheckVar(options and options.mashamount, 20))
        elseif mode == 'timed' then
            Citizen.InvokeNative(0x1473D3AF51D54276, PromptClass.Prompt,
                CheckVar(options and options.depletiontime, 10000))
        end


        self:SetTabAmount(PromptClass.tabIndex) -- Update tabAmount if necessary

        Citizen.InvokeNative(0xC5F428EE08FA7F2C, PromptClass.Prompt, CheckVar(pulsing, true))
        PromptRegisterEnd(PromptClass.Prompt)

        ----------------- Prompt Specific APIs below -----------------
        function PromptClass:TogglePrompt(toggle)
            Citizen.InvokeNative(0x71215ACCFDE075EE, self.Prompt, toggle)
        end

        function PromptClass:EnabledPrompt(toggle)
            PromptSetEnabled(self.Prompt, toggle)
        end

        function PromptClass:DeletePrompt()
            Citizen.InvokeNative(0x00EDE88D4D13CF59, self.Prompt) -- UiPromptDelete
        end

        function PromptClass:HasCompleted(hideoncomplete)
            if self.Mode == 'click' then
                return Citizen.InvokeNative(0xC92AC953F0A982AE, self.Prompt) --UiPromptHasStandardModeCompleted
            end

            if self.Mode == 'hold' or self.Mode == 'customhold' then
                local result = Citizen.InvokeNative(0xE0F65F0640EF0617, self.Prompt) --UiPromptHasHoldModeCompleted

                if result then
                    Wait(500) --Prevents the spamming of the result (ensures it only gets triggered 1 time)
                end

                return result
            end

            if self.Mode == 'mash' then
                local result = Citizen.InvokeNative(0x845CE958416DC473, self.Prompt) --UiPromptHasMashModeCompleted
                if result then
                    Wait(500)                                                                              --Prevents the spamming of the result (ensures it only gets triggered 1 time)
                end

                return result
            end

            if self.Mode == 'timed' then
                local result = Citizen.InvokeNative(0x3CE854D250A88DAF, self.Prompt[PromptClass.tabIndex]) --UiPromptHasPressedTimedModeCompleted

                if result and CheckVar(hideoncomplete, true) then
                    self:TogglePrompt(false)
                    Wait(200)
                end

                return result
            end
        end

        function PromptClass:HasFailed(hideoncomplete)
            if self.Mode == 'click' or self.Mode == 'hold' or self.Mode == 'customhold' then
                return false
            end

            if self.Mode == 'mash' then
                local result = Citizen.InvokeNative(0x25B18E530CF39D6F, self.Prompt[PromptClass.tabIndex]) --UiPromptHasMashModeFailed

                if result then
                    self:TogglePrompt(false)
                end

                return result
            end

            if self.Mode == 'timed' then
                local result = Citizen.InvokeNative(0x1A17B9ECFF617562, self.Prompt[PromptClass.tabIndex]) --UiPromptHasPressedTimedModeFailed

                if result and CheckVar(hideoncomplete, true) then
                    self:TogglePrompt(false)
                    Wait(200)
                end

                return result
            end
        end

        return PromptClass
    end

    return GroupsClass
end
