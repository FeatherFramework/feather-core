<script setup>
// import { computed } from 'vue'

const props = defineProps({
    amount: {
        required: true
    },
    type: {
        required: true
    }
})



</script>

<template>
    <div class="relative pt-4 flex object">
        <img class="w-12 h-12 align-middle" v-if="props.type === 'money'" src="../assets/icons/money.png" />
        <img class="w-12 h-12 align-middle" v-if="props.type === 'gold'" src="../assets/icons/gold.png" />
        <img class="w-12 h-12 align-middle" v-if="props.type === 'token'" src="../assets/icons/token.png" />

        <div :class="`pl-2 text-5xl chinarocks align-middle ${type=='gold' ? 'gold' : ''} ${type=='token' ? 'token' : ''}`">{{ props.amount }}</div>
    </div>
</template>
<style scoped> 

    .token {
        color: #0195CC;
    }

    .gold {
        color: #B19328;
    }
</style>
