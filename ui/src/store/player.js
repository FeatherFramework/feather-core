import { defineStore } from 'pinia';

export const usePlayerStore = defineStore('player', {
    state: () => ({
        first_name: '',
        last_name: '',
        level: 0,
        xp: 0,
        pvp: false,
        id: null,
        money: '0.00',
        gold: '0.00',
        token: '0',
        gain: 0,
        lang: null
    }),
    getters: {
    },
    actions: {
        storePlayer(player, config) {
            this.first_name = player.first_name
            this.last_name = player.last_name
            this.level = player.level
            this.xp = player.xp
            this.money = player.dollars
            this.gold = player.gold
            this.gain = config.xp.perLevel
            this.token = player.tokens
            this.id = player.id
            this.lang = player.lang            
        },
        updateLocale(locale) {
            this.lang = locale   
        }
    },
})