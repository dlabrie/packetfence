<template>
  <b-tab title="IPv6 Addresses">
    <template v-slot:title>
      {{ $t('IPv6') }} <b-badge pill v-if="node && node.ip6 && node.ip6.history && node.ip6.history.length > 0" variant="light" class="ml-1">{{ node.ip6.history.length }}</b-badge>
    </template>
    <b-table v-if="node && node.ip6"
      :items="node.ip6.history" :fields="ipLogFields" :sort-by="iplogSortBy" :sort-desc="iplogSortDesc" responsive show-empty sort-icon-left striped>
      <template v-slot:empty>
        <base-table-empty :is-loading="isLoading" text="">{{ $t('No IPv6 addresses found') }}</base-table-empty>
      </template>
    </b-table>
  </b-tab>
</template>
<script>
import {
  BaseTableEmpty
} from '@/components/new/'

const components = {
  BaseTableEmpty
}

const props = {
  id: {
    type: String
  }
}

import { computed, ref, toRefs } from '@vue/composition-api'
import { usePropsWrapper } from '@/composables/useProps'
import { useStore } from '../_composables/useCollection'
import { ipLogFields } from '../_config/'

const setup = (props, context) => {

  const { id } = toRefs(props)
  const { root: { $store } = {} } = context

  const node = computed(() => $store.state.$_nodes.nodes[id.value])

  const iplogSortBy = ref('end_time')
  const iplogSortDesc = ref(true)

  // merge props w/ params in useStore methods
  const _useStore = $store => usePropsWrapper(useStore($store), props)
  const {
    isLoading
  } = _useStore($store)

  return {
    ipLogFields,

    iplogSortBy,
    iplogSortDesc,
    isLoading,
    node
  }
}
// @vue/component
export default {
  name: 'tab-ip6-logs',
  inheritAttrs: false,
  components,
  props,
  setup
}
</script>