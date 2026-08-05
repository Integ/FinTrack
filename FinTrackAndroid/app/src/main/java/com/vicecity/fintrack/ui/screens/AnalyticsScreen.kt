package com.vicecity.fintrack.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CenterAlignedTopAppBar
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SegmentedButton
import androidx.compose.material3.SegmentedButtonDefaults
import androidx.compose.material3.SingleChoiceSegmentedButtonRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vicecity.fintrack.FinTrackViewModel
import com.vicecity.fintrack.R
import com.vicecity.fintrack.data.DailyTotal
import com.vicecity.fintrack.data.ReportPeriod
import com.vicecity.fintrack.ui.components.BreakdownLine
import com.vicecity.fintrack.ui.components.formatMoney
import com.vicecity.fintrack.ui.theme.Coral
import com.vicecity.fintrack.ui.theme.Mint
import java.math.BigDecimal
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AnalyticsScreen(viewModel: FinTrackViewModel, contentPadding: PaddingValues) {
    var period by remember { mutableStateOf(ReportPeriod.WEEK) }
    val summary = viewModel.summary(period)
    val totals = viewModel.dailyTotals(period)
    val periods = ReportPeriod.entries

    Column(modifier = Modifier.fillMaxSize().padding(bottom = contentPadding.calculateBottomPadding())) {
        CenterAlignedTopAppBar(
            title = { Text(stringResource(R.string.income_trends), fontWeight = FontWeight.SemiBold) },
        )
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            item {
                SingleChoiceSegmentedButtonRow(modifier = Modifier.fillMaxWidth()) {
                    periods.forEachIndexed { index, item ->
                        SegmentedButton(
                            selected = item == period,
                            onClick = { period = item },
                            shape = SegmentedButtonDefaults.itemShape(index, periods.size),
                            label = {
                                Text(
                                    stringResource(
                                        when (item) {
                                            ReportPeriod.TODAY -> R.string.today
                                            ReportPeriod.WEEK -> R.string.seven_days
                                            ReportPeriod.MONTH -> R.string.thirty_days
                                        }
                                    )
                                )
                            },
                        )
                    }
                }
            }
            item {
                Column(
                    modifier = Modifier.fillMaxWidth().padding(vertical = 12.dp),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(7.dp),
                ) {
                    Text(stringResource(R.string.net_income), color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Text(
                        formatMoney(summary.profit, viewModel.currencyChoice),
                        style = MaterialTheme.typography.headlineLarge,
                        fontWeight = FontWeight.Bold,
                        color = if (summary.profit >= BigDecimal.ZERO) MaterialTheme.colorScheme.onSurface else Coral,
                    )
                    Text(
                        stringResource(R.string.business_profit_explanation),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            item {
                Card(shape = RoundedCornerShape(22.dp)) {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(stringResource(R.string.daily_cash_flow), fontWeight = FontWeight.SemiBold)
                            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                ChartLegend(stringResource(R.string.income), Mint)
                                ChartLegend(stringResource(R.string.outflow), Coral)
                            }
                        }
                        CashFlowChart(
                            totals = totals,
                            description = stringResource(R.string.cash_flow_chart_description),
                            modifier = Modifier.fillMaxWidth().height(220.dp),
                        )
                        if (totals.isNotEmpty()) {
                            val formatter = DateTimeFormatter.ofLocalizedDate(FormatStyle.SHORT)
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                                Text(totals.first().date.format(formatter), style = MaterialTheme.typography.labelSmall)
                                if (totals.size > 2) Text(totals[totals.lastIndex / 2].date.format(formatter), style = MaterialTheme.typography.labelSmall)
                                Text(totals.last().date.format(formatter), style = MaterialTheme.typography.labelSmall)
                            }
                        }
                    }
                }
            }
            item {
                Card(shape = RoundedCornerShape(22.dp)) {
                    Column(modifier = Modifier.fillMaxWidth().padding(18.dp)) {
                        Text(stringResource(R.string.breakdown), fontWeight = FontWeight.SemiBold, modifier = Modifier.padding(bottom = 7.dp))
                        BreakdownLine(stringResource(R.string.business_income), formatMoney(summary.income, viewModel.currencyChoice), Mint)
                        HorizontalDivider(modifier = Modifier.padding(start = 34.dp))
                        BreakdownLine(stringResource(R.string.related_costs), formatMoney(summary.costs, viewModel.currencyChoice), Color(0xFFF59E0B))
                        HorizontalDivider(modifier = Modifier.padding(start = 34.dp))
                        BreakdownLine(stringResource(R.string.extra_expenses), formatMoney(summary.expenses, viewModel.currencyChoice), Coral)
                        HorizontalDivider(modifier = Modifier.padding(start = 34.dp))
                        BreakdownLine(stringResource(R.string.total_outflow), formatMoney(summary.totalOutflow, viewModel.currencyChoice), MaterialTheme.colorScheme.onSurface)
                    }
                }
            }
        }
    }
}

@Composable
private fun ChartLegend(label: String, color: Color) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(5.dp)) {
        Box(Modifier.size(7.dp).background(color, CircleShape))
        Text(label, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
    }
}

@Composable
private fun CashFlowChart(totals: List<DailyTotal>, description: String, modifier: Modifier = Modifier) {
    val gridColor = MaterialTheme.colorScheme.outlineVariant
    val density = LocalDensity.current
    val gap = with(density) { 2.dp.toPx() }
    Canvas(modifier = modifier.clip(RoundedCornerShape(10.dp)).semantics { contentDescription = description }) {
        if (totals.isEmpty()) return@Canvas
        val maximum = totals.maxOf { maxOf(it.income, it.outflow) }.toFloat().coerceAtLeast(1f)
        repeat(4) { index ->
            val y = size.height * index / 3f
            drawLine(gridColor, Offset(0f, y), Offset(size.width, y), strokeWidth = 1f)
        }
        val groupWidth = size.width / totals.size
        val barWidth = ((groupWidth - gap * 3) / 2).coerceAtLeast(1f)
        totals.forEachIndexed { index, item ->
            val left = index * groupWidth + gap
            val incomeHeight = size.height * item.income.toFloat() / maximum
            val outflowHeight = size.height * item.outflow.toFloat() / maximum
            drawRect(Mint, Offset(left, size.height - incomeHeight), Size(barWidth, incomeHeight))
            drawRect(Coral, Offset(left + barWidth + gap, size.height - outflowHeight), Size(barWidth, outflowHeight))
        }
    }
}
