package com.vicecity.fintrack.ui.screens

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.FileDownload
import androidx.compose.material.icons.rounded.FileUpload
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vicecity.fintrack.BuildConfig
import com.vicecity.fintrack.FinTrackViewModel
import com.vicecity.fintrack.R
import com.vicecity.fintrack.data.CsvCodec
import com.vicecity.fintrack.data.CsvFormatException
import com.vicecity.fintrack.data.CurrencyChoice
import com.vicecity.fintrack.data.Transaction
import com.vicecity.fintrack.data.financialSummary
import com.vicecity.fintrack.ui.components.formatMoney
import com.vicecity.fintrack.ui.components.resolvedCurrencyCode
import java.time.LocalDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(viewModel: FinTrackViewModel, contentPadding: PaddingValues) {
    val context = LocalContext.current
    var currencyDialogVisible by remember { mutableStateOf(false) }
    var importedPreview by remember { mutableStateOf<List<Transaction>>(emptyList()) }
    var importChoiceVisible by remember { mutableStateOf(false) }
    var message by remember { mutableStateOf<String?>(null) }

    val exportLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.CreateDocument("text/csv")
    ) { uri ->
        if (uri != null) {
            runCatching {
                val output = requireNotNull(context.contentResolver.openOutputStream(uri))
                output.bufferedWriter(Charsets.UTF_8).use { writer ->
                    writer.write("\uFEFF")
                    writer.write(CsvCodec.encode(viewModel.transactions))
                }
            }.onFailure { error ->
                message = context.getString(R.string.export_failed, error.localizedMessage.orEmpty())
            }
        }
    }
    val importLauncher = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocument()) { uri ->
        if (uri != null) {
            runCatching {
                val input = requireNotNull(context.contentResolver.openInputStream(uri))
                val text = input.bufferedReader(Charsets.UTF_8).use { it.readText() }
                CsvCodec.decode(text)
            }.onSuccess { records ->
                if (records.isEmpty()) {
                    message = context.getString(R.string.no_import_records)
                } else {
                    importedPreview = records
                    importChoiceVisible = true
                }
            }.onFailure { error ->
                message = if (error is CsvFormatException) {
                    context.getString(R.string.csv_invalid_row, error.row)
                } else {
                    context.getString(R.string.import_failed, error.localizedMessage.orEmpty())
                }
            }
        }
    }
    val summary = viewModel.transactions.financialSummary()
    val systemCurrency = resolvedCurrencyCode(CurrencyChoice.SYSTEM)

    Column(modifier = Modifier.fillMaxSize().padding(bottom = contentPadding.calculateBottomPadding())) {
        CenterAlignedTopAppBar(
            title = { Text(stringResource(R.string.nav_settings), fontWeight = FontWeight.SemiBold) },
        )
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            item {
                SettingsSection(title = stringResource(R.string.display)) {
                    SettingsRow(
                        label = stringResource(R.string.currency),
                        value = currencyLabel(viewModel.currencyChoice, systemCurrency),
                        onClick = { currencyDialogVisible = true },
                    )
                }
            }
            item {
                SettingsSection(title = stringResource(R.string.data_backup)) {
                    ActionRow(
                        label = stringResource(R.string.export_csv),
                        icon = { Icon(Icons.Rounded.FileUpload, contentDescription = null) },
                        enabled = viewModel.transactions.isNotEmpty(),
                        onClick = { exportLauncher.launch("fintrack_backup_${LocalDate.now()}.csv") },
                    )
                    HorizontalDivider(modifier = Modifier.padding(start = 54.dp))
                    ActionRow(
                        label = stringResource(R.string.import_csv),
                        icon = { Icon(Icons.Rounded.FileDownload, contentDescription = null) },
                        onClick = { importLauncher.launch(arrayOf("text/csv", "text/plain", "text/*")) },
                    )
                    Text(
                        stringResource(R.string.backup_explanation),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(16.dp),
                    )
                }
            }
            item {
                SettingsSection(title = stringResource(R.string.about)) {
                    ValueRow(stringResource(R.string.total_net_profit), formatMoney(summary.profit, viewModel.currencyChoice))
                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                    ValueRow(stringResource(R.string.total_income), formatMoney(summary.income, viewModel.currencyChoice))
                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                    ValueRow(stringResource(R.string.average_profit_margin), "%.1f%%".format(summary.profitMargin.toDouble() * 100))
                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                    ValueRow(stringResource(R.string.version), BuildConfig.VERSION_NAME)
                    HorizontalDivider(modifier = Modifier.padding(start = 16.dp))
                    ValueRow(stringResource(R.string.record_count), stringResource(R.string.record_count_value, viewModel.transactions.size))
                }
            }
        }
    }

    if (currencyDialogVisible) {
        AlertDialog(
            onDismissRequest = { currencyDialogVisible = false },
            title = { Text(stringResource(R.string.currency)) },
            text = {
                Column {
                    CurrencyChoice.entries.forEach { choice ->
                        Row(
                            modifier = Modifier.fillMaxWidth().clickable {
                                viewModel.selectCurrency(choice)
                                currencyDialogVisible = false
                            }.padding(vertical = 5.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            RadioButton(selected = choice == viewModel.currencyChoice, onClick = null)
                            Text(currencyLabel(choice, systemCurrency), modifier = Modifier.padding(start = 8.dp))
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(onClick = { currencyDialogVisible = false }) { Text(stringResource(R.string.cancel)) }
            },
        )
    }

    if (importChoiceVisible) {
        AlertDialog(
            onDismissRequest = { importChoiceVisible = false },
            title = { Text(stringResource(R.string.choose_import_mode, importedPreview.size)) },
            text = { Text(stringResource(R.string.backup_explanation)) },
            confirmButton = {
                TextButton(onClick = {
                    viewModel.append(importedPreview)
                    message = context.getString(R.string.appended_records, importedPreview.size)
                    importChoiceVisible = false
                }) { Text(stringResource(R.string.append_records)) }
            },
            dismissButton = {
                Column(horizontalAlignment = Alignment.End) {
                    TextButton(onClick = {
                        viewModel.replaceAll(importedPreview)
                        message = context.getString(R.string.imported_records, importedPreview.size)
                        importChoiceVisible = false
                    }) { Text(stringResource(R.string.replace_records), color = MaterialTheme.colorScheme.error) }
                    TextButton(onClick = { importChoiceVisible = false }) { Text(stringResource(R.string.cancel)) }
                }
            },
        )
    }

    message?.let { value ->
        AlertDialog(
            onDismissRequest = { message = null },
            title = { Text(stringResource(R.string.app_name)) },
            text = { Text(value) },
            confirmButton = { TextButton(onClick = { message = null }) { Text(stringResource(R.string.ok)) } },
        )
    }
}

@Composable
private fun SettingsSection(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(7.dp)) {
        Text(
            title,
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.padding(start = 12.dp),
        )
        Card(shape = RoundedCornerShape(20.dp)) { Column(content = { content() }) }
    }
}

@Composable
private fun SettingsRow(label: String, value: String, onClick: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(label, modifier = Modifier.weight(1f))
        Text(value, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Icon(Icons.Rounded.ChevronRight, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun ActionRow(
    label: String,
    icon: @Composable () -> Unit,
    enabled: Boolean = true,
    onClick: () -> Unit,
) {
    Row(
        modifier = Modifier.fillMaxWidth().clickable(enabled = enabled, onClick = onClick).padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        icon()
        Text(label, color = if (enabled) MaterialTheme.colorScheme.onSurface else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.38f))
    }
}

@Composable
private fun ValueRow(label: String, value: String) {
    Row(modifier = Modifier.fillMaxWidth().padding(16.dp), horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label)
        Text(value, color = MaterialTheme.colorScheme.onSurfaceVariant, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun currencyLabel(choice: CurrencyChoice, systemCode: String): String = when (choice) {
    CurrencyChoice.SYSTEM -> stringResource(R.string.system_default_currency, systemCode)
    CurrencyChoice.CNY -> stringResource(R.string.currency_cny)
    CurrencyChoice.USD -> stringResource(R.string.currency_usd)
    CurrencyChoice.CAD -> stringResource(R.string.currency_cad)
    CurrencyChoice.EUR -> stringResource(R.string.currency_eur)
}
