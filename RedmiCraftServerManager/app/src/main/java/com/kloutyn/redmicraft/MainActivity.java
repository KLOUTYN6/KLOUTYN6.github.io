package com.kloutyn.redmicraft;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.text.format.Formatter;
import android.view.Gravity;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

public class MainActivity extends Activity {
    private TextView status;
    private TextView log;
    private boolean offline = false;
    private static final String TERMUX = "com.termux";
    private static final String HOME = "/data/data/com.termux/files/home";

    @Override public void onCreate(Bundle b) {
        super.onCreate(b);
        buildUi();
    }

    private TextView tv(String s, int sp) {
        TextView t = new TextView(this);
        t.setText(s); t.setTextSize(sp); t.setTextColor(Color.WHITE);
        t.setPadding(18, 12, 18, 12);
        return t;
    }

    private Button btn(String s) {
        Button b = new Button(this);
        b.setText(s); b.setAllCaps(false);
        return b;
    }

    private void buildUi() {
        ScrollView scroll = new ScrollView(this);
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(16,18,16,14);
        root.setBackgroundColor(Color.rgb(16,16,20));

        TextView title = tv("REDMICRAFT", 28);
        title.setTextColor(Color.rgb(210,90,255));
        title.setGravity(Gravity.CENTER);
        root.addView(title);

        TextView sub = tv("Minecraft Java 26.3 • Redmi 9",15);
        sub.setGravity(Gravity.CENTER);
        root.addView(sub);

        status = tv("Status: Not configured",16);
        root.addView(status);

        root.addView(tv("LAN IP: " + getIp() + "\nPort: 25565\nRAM: 2 GB\nPlayers: 10",15));

        LinearLayout r1 = new LinearLayout(this); r1.setOrientation(LinearLayout.HORIZONTAL);
        Button setup=btn("⚙ Setup"), start=btn("▶ Start"), stop=btn("■ Stop"), restart=btn("↻ Restart");
        r1.addView(setup, new LinearLayout.LayoutParams(0,-2,1));
        r1.addView(start, new LinearLayout.LayoutParams(0,-2,1));
        root.addView(r1);

        LinearLayout r2 = new LinearLayout(this); r2.setOrientation(LinearLayout.HORIZONTAL);
        r2.addView(stop, new LinearLayout.LayoutParams(0,-2,1));
        r2.addView(restart, new LinearLayout.LayoutParams(0,-2,1));
        root.addView(r2);

        Button offlineBtn=btn("🔓 Offline Authentication: OFF");
        Button backup=btn("💾 Backup world");
        Button console=btn("🖥 Open Termux Console");
        root.addView(offlineBtn); root.addView(backup); root.addView(console);

        log = tv("Ready.\n\nTap SETUP first.\nTermux must be installed and configured to allow external RUN_COMMAND requests.",14);
        root.addView(log);

        setup.setOnClickListener(v -> {
            status.setText("Status: Setting up…");
            runTermux(
                "set -e; " +
                "mkdir -p ~/minecraft-server/backups; " +
                "pkg update -y; " +
                "pkg install -y openjdk-25 curl jq tar; " +
                "cd ~/minecraft-server; " +
                "if [ ! -f server.jar ]; then " +
                "URL=$(curl -fsSL https://piston-meta.mojang.com/mc/game/version_manifest_v2.json | " +
                "jq -r '[.versions[] | select(.id==\"26.3\")][0].url' | " +
                "xargs -r curl -fsSL | jq -r '.downloads.server.url'); " +
                "curl -fL \"$URL\" -o server.jar; fi; " +
                "printf 'eula=true\nserver-port=25565\nmax-players=10\nview-distance=6\nsimulation-distance=4\nonline-mode=%s\n' " +
                (offline ? "false" : "true") + " > server.properties; " +
                "echo SETUP_COMPLETE",
                "SETUP"
            );
        });

        start.setOnClickListener(v -> {
            status.setText("Status: Starting…");
            runTermux(
                "cd ~/minecraft-server; " +
                "if pgrep -f 'java.*server.jar' >/dev/null; then echo ALREADY_RUNNING; else " +
                "nohup java -Xms1G -Xmx2G -jar server.jar nogui > server.log 2>&1 & echo START_REQUESTED; fi",
                "START"
            );
        });

        stop.setOnClickListener(v -> {
            status.setText("Status: Stopping…");
            runTermux(
                "cd ~/minecraft-server; " +
                "if pgrep -f 'java.*server.jar' >/dev/null; then " +
                "pkill -f 'java.*server.jar' || true; fi; echo STOP_REQUESTED",
                "STOP"
            );
        });

        restart.setOnClickListener(v -> {
            status.setText("Status: Restarting…");
            runTermux(
                "cd ~/minecraft-server; " +
                "pkill -f 'java.*server.jar' || true; sleep 2; " +
                "nohup java -Xms1G -Xmx2G -jar server.jar nogui > server.log 2>&1 & echo RESTART_REQUESTED",
                "RESTART"
            );
        });

        offlineBtn.setOnClickListener(v -> {
            offline = !offline;
            offlineBtn.setText("🔓 Offline Authentication: " + (offline ? "ON" : "OFF"));
            runTermux(
                "cd ~/minecraft-server; touch server.properties; " +
                "sed -i '/^online-mode=/d' server.properties; " +
                "echo online-mode=" + (offline ? "false" : "true"),
                "AUTH"
            );
        });

        backup.setOnClickListener(v -> runTermux(
            "cd ~/minecraft-server; mkdir -p backups; " +
            "tar -czf backups/world-$(date +%Y%m%d-%H%M%S).tar.gz world 2>/dev/null || true; echo BACKUP_COMPLETE",
            "BACKUP"
        ));

        console.setOnClickListener(v -> {
            try {
                Intent i = new Intent();
                i.setClassName(TERMUX, "com.termux.app.TermuxActivity");
                startActivity(i);
            } catch (Exception e) {
                log.setText("Termux is not installed.");
            }
        });

        root.addView(tv("NOTE: This manager uses Termux as the Java/Minecraft backend. " +
                        "Offline Authentication disables account authentication and can allow username impersonation.",13));

        scroll.addView(root);
        setContentView(scroll);
    }

    private void runTermux(String command, String label) {
        Intent i = new Intent("com.termux.RUN_COMMAND");
        i.setPackage(TERMUX);
        i.putExtra("com.termux.RUN_COMMAND_PATH", "/data/data/com.termux/files/usr/bin/bash");
        i.putExtra("com.termux.RUN_COMMAND_ARGUMENTS", new String[]{"-lc", command});
        i.putExtra("com.termux.RUN_COMMAND_WORKDIR", HOME);
        i.putExtra("com.termux.RUN_COMMAND_BACKGROUND", true);
        i.putExtra("com.termux.RUN_COMMAND_COMMAND_DESCRIPTION", label);
        try {
            sendBroadcast(i);
            log.setText(label + " command sent to Termux.\n");
        } catch (Exception e) {
            log.setText("Could not send command: " + e.getMessage());
        }
    }

    private String getIp() {
        try {
            WifiManager wm=(WifiManager)getApplicationContext().getSystemService(WIFI_SERVICE);
            return Formatter.formatIpAddress(wm.getConnectionInfo().getIpAddress());
        } catch(Exception e) { return "unknown"; }
    }
}
