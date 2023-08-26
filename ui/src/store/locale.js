import { defineStore } from 'pinia';

export const useLocaleStore = defineStore('locale', {
    state: () => ({
        locale: {}
    }),
    getters: {
    },
    actions: {
        storeLocale(locale) {
            this.locale = locale
        }
    },
})