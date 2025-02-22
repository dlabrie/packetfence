<template>
  <b-container class="px-0" fluid>

    <b-row align-h="end" v-if="!hasQuery">
      <b-col cols="auto" class="mr-auto my-3">
        <slot />
      </b-col>
      <b-col cols="auto" class="my-3 align-self-end d-flex">
        <base-search-input-limit v-if="hasLimit"
          :value="limit" @input="setLimit"
          size="md"
          :limits="limits"
          :disabled="isLoading"
        />
        <base-search-input-page v-if="hasCursor"
          :value="page" @input="setPage"
          class="ml-3"
          :limit="limit"
          :total-rows="totalRows"
          :disabled="isLoading"
        />
      </b-col>
    </b-row>

    <b-table ref="tableRef"
      :busy="isLoading"
      :hover="items.length > 0"
      :items="items"
      :fields="visibleColumns"
      class="mb-0"
      no-local-sorting
      no-provider-sorting
      responsive
      selectable
      show-empty
      striped
      @row-selected="onRowSelected"
    >
      <template v-slot:empty>
        <slot name="emptySearch" v-bind="{ isLoading }">
          <base-table-empty :is-loading="isLoading">{{ $t('No results found') }}</base-table-empty>
        </slot>
      </template>
      <template #head(selected)>
        <span @click.stop.prevent="onAllSelected">
          <template v-if="selected.length > 0">
            <icon name="check-square" class="bg-white text-success" scale="1.125" style="max-width: 1.125em;" />
          </template>
          <template v-else>
            <icon name="square" class="border border-1 border-gray bg-white text-light" scale="1.125" style="max-width: 1.125em;" />
          </template>
        </span>
      </template>
      <template #head(buttons)>
        <base-search-input-columns
          :disabled="isLoading"
          :value="columns"
          @input="setColumns"
        />
      </template>
      <template v-for="nodeField in nodeFields"
        v-slot:[`cell(${nodeField})`]="{ field, value }">
        <router-link :key="nodeField"
          :to="{ path: `/node/${value}` }"><mac v-text="value" /></router-link>
      </template>
      <template v-for="personField in personFields"
        v-slot:[`cell(${personField})`]="{ field, value }">
        <router-link :key="personField"
          :to="{ path: `/user/${value}` }">{{ value }}</router-link>
      </template>
      <template v-for="roleField in roleFields"
        v-slot:[`cell(${roleField})`]="{ field, value }">
        <router-link :key="roleField"
          :to="{ path: `/configuration/role/${value}` }">{{ value }}</router-link>
      </template>
      <template #cell(selected)="{ index, rowSelected }">
        <span @click.stop="onItemSelected(index)">
          <template v-if="rowSelected">
            <icon name="check-square" class="bg-white text-success" scale="1.125" />
          </template>
          <template v-else>
            <icon name="square" class="border border-1 border-gray bg-white text-light" scale="1.125" />
          </template>
        </span>
      </template>
    </b-table>
    <b-container fluid v-if="selected.length"
      class="mt-3 p-0">
      <b-dropdown variant="outline-primary" toggle-class="text-decoration-none">
        <template #button-content>
          {{ $t('{num} selected', { num: selected.length }) }}
        </template>
        <b-dropdown-item @click="onBulkExport">{{ $t('Export to CSV') }}</b-dropdown-item>
      </b-dropdown>
    </b-container>
  </b-container>
</template>
<script>
import {
  BaseSearchInputColumns,
  BaseSearchInputLimit,
  BaseSearchInputPage,
  BaseTableEmpty
} from '@/components/new/'
const components = {
  BaseSearchInputColumns,
  BaseSearchInputLimit,
  BaseSearchInputPage,
  BaseTableEmpty
}

const props = {
  meta: {
    type: Object
  }
}

import { computed, ref, toRefs } from '@vue/composition-api'
import { useBootstrapTableSelected } from '@/composables/useBootstrap'
import { useTableColumnsItems } from '@/composables/useCsv'
import { useDownload } from '@/composables/useDownload'
import acl from '@/utils/acl'
import { useSearchFactory } from '../_search'

const setup = (props, context) => {

  const {
    meta
  } = toRefs(props)

  const { root: { $router } = {} } = context

  const useSearch = useSearchFactory(meta)
  const search = useSearch()

  const { columns = [], query_fields = [] } = meta.value

  const hasCursor = computed(() => {
    const { has_cursor } = meta.value
    return has_cursor
  })

  const hasQuery = computed(() => {
    const { query_fields = [] } = meta.value
    return !!query_fields.length
  })

  const hasLimit = computed(() => {
    const { has_limit } = meta.value
    return has_limit
  })

  if (query_fields.length === 0) {
    // no search available
    //  use empty search for default criteria
    search.defaultCondition = () => undefined
    // trigger search
    search.reSearch()
  }

  const columnsIs = computed(() => {
    return columns.reduce((assoc, column) => {
      const { name, is_node, is_person, is_role } = column
      return { ...assoc, [name]: { is_node, is_person, is_role }}
    }, {})
  })

  const {
    items,
    visibleColumns
  } = toRefs(search)

  const tableRef = ref(null)
  let selected = useBootstrapTableSelected(tableRef, items, null)

  const onBulkExport = () => {
    const {
      selectedItems
    } = selected
    const filename = `${$router.currentRoute.path.slice(1).replace('/', '-')}-${(new Date()).toISOString()}.csv`
    const csv = useTableColumnsItems(visibleColumns.value, selectedItems.value)
    useDownload(filename, csv, 'text/csv')
  }

  // dynamic b-table slots
  const nodeFields = computed(() => {
    if (acl.$can('read', 'nodes')) {
      const { columns = [] } = meta.value
      return columns
        .filter(column => column.is_node)
        .map(column => column.name)
    }
    return []
  })
  const personFields = computed(() => {
    if (acl.$can('read', 'users')) {
      const { columns = [] } = meta.value
      return columns
        .filter(column => column.is_person)
        .map(column => column.name)
    }
    return []
  })
  const roleFields = computed(() => {
      const { columns = [] } = meta.value
      return columns
        .filter(column => column.is_role)
        .map(column => column.name)
  })

  return {
    hasCursor,
    hasQuery,
    hasLimit,
    tableRef,
    columnsIs,
    ...selected,
    ...toRefs(search),
    onBulkExport,

    nodeFields,
    personFields,
    roleFields
  }
}
// @vue/component
export default {
  name: 'the-table',
  components,
  props,
  setup
}
</script>