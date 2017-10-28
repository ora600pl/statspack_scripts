REM This scirpt draws chart of wait class usage, broke into separate snap_ids use it in one day or few hours period
REM Usage: @stats_top_event_snaps_chart.sql instance_number scale_for_bar_to_display date_from date_to
REM by Kamil Stawiarski (@ora600pl)

set linesize 260
set pagesize 0
set verify off
set trimspool on
column snap_time format a22
column wait_class format a20
column bar format a&&2

with v_system_class_wait as
(
select EVENT, WAIT_CLASS, TIME_WAITED_MICRO-lag(TIME_WAITED_MICRO,1,TIME_WAITED_MICRO) over (partition by event order by sys_ev.SNAP_ID) as waited_micro_diff,
       sys_ev.snap_id, TIME_WAITED_MICRO
from  STATS$SYSTEM_EVENT sys_ev, stats$snapshot snap, v$event_name e
where sys_ev.snap_id=snap.snap_id
and   snap.SNAP_TIME between to_date('&&3','YYYY-MM-DD:HH24:MI') and to_date('&&4','YYYY-MM-DD:HH24:MI')
and   wait_Class not in ('Idle','Other')
and   sys_ev.instance_number=&&1
and   snap.instance_number=&&1
and   snap.instance_number=sys_ev.instance_number
and   sys_ev.event_id=e.event_id
), v_system_rank as
(
select snap_id, WAIT_CLASS, sum(waited_micro_diff) as sm_waited_micro_diff, round(max(sum(waited_micro_diff)) over ()/&&2) as scale_ratio
from v_system_class_wait
group by snap_id, WAIT_CLASS
)
select to_char(snap2.SNAP_TIME,'YYYY-MM-DD:HH24:MI:SS') as snap_time,snap2.snap_id,WAIT_CLASS,sm_waited_micro_diff,
       lpad('*',round(sm_waited_micro_diff/scale_ratio),'*') as bar
from v_system_rank sr, stats$snapshot snap2
where sr.snap_id=snap2.snap_id
and   snap2.instance_number=&&1
order by snap2.SNAP_TIME,WAIT_CLASS
/

set pagesize 200
