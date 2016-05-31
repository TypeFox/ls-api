package io.typefox.lsapi.services.json

import io.typefox.lsapi.NotificationMessage
import io.typefox.lsapi.RequestMessage
import io.typefox.lsapi.ResponseMessage
import io.typefox.lsapi.services.LanguageServer
import java.io.PrintWriter
import org.eclipse.xtend.lib.annotations.Accessors

class LoggingJsonAdapter extends LanguageServerToJsonAdapter {

	@Accessors(PUBLIC_SETTER)
	PrintWriter errorLog

	@Accessors(PUBLIC_SETTER)
	PrintWriter messageLog

	new(LanguageServer server) {
		super(server)
		protocol.addErrorListener [ message, throwable |
			if (errorLog !== null) {
				if (throwable !== null)
					throwable.printStackTrace(errorLog)
				else if (message !== null)
					errorLog.println(message)
				errorLog.flush()
			}
		]
		protocol.addIncomingMessageListener [ message, json |
			if (messageLog !== null) {
				switch message {
					RequestMessage:
						messageLog.println('Client Request:\n\t' + json)
					NotificationMessage:
						messageLog.println('Client Notification:\n\t' + json)
				}
				messageLog.flush()
			}
		]
		protocol.addOutgoingMessageListener [ message, json |
			if (messageLog !== null) {
				switch message {
					ResponseMessage:
						messageLog.println('Server Response:\n\t' + json)
					NotificationMessage:
						messageLog.println('Server Notification:\n\t' + json)
				}
				messageLog.flush()
			}
		]
	}

}
