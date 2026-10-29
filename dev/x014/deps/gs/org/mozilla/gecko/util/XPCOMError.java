/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.mozilla.gecko.util;

public final class XPCOMError {
  /** Check if the error code corresponds to a failure */
  public static boolean failed(long err) {
    return (err & 0x80000000L) != 0;
  }

  /** Check if the error code corresponds to a failure */
  public static boolean succeeded(long err) {
    return !failed(err);
  }

  /** Extract the error code part of the error message */
  public static int getErrorCode(long err) {
    return (int)(err & 0xffffL);
  }

  /** Extract the error module part of the error message */
  public static int getErrorModule(long err) {
    return (int)(((err >> 16) - NS_ERROR_MODULE_BASE_OFFSET) & 0x1fffL);
  }

  public static final int NS_ERROR_MODULE_BASE_OFFSET = 69;


  public static final int NS_ERROR_MODULE_XPCOM = 1;

  public static final int NS_ERROR_MODULE_BASE = 2;

  public static final int NS_ERROR_MODULE_GFX = 3;

  public static final int NS_ERROR_MODULE_WIDGET = 4;

  public static final int NS_ERROR_MODULE_CALENDAR = 5;

  public static final int NS_ERROR_MODULE_NETWORK = 6;

  public static final int NS_ERROR_MODULE_PLUGINS = 7;

  public static final int NS_ERROR_MODULE_LAYOUT = 8;

  public static final int NS_ERROR_MODULE_HTMLPARSER = 9;

  public static final int NS_ERROR_MODULE_RDF = 10;

  public static final int NS_ERROR_MODULE_UCONV = 11;

  public static final int NS_ERROR_MODULE_REG = 12;

  public static final int NS_ERROR_MODULE_FILES = 13;

  public static final int NS_ERROR_MODULE_DOM = 14;

  public static final int NS_ERROR_MODULE_IMGLIB = 15;

  public static final int NS_ERROR_MODULE_EDITOR = 17;

  public static final int NS_ERROR_MODULE_XPCONNECT = 18;

  public static final int NS_ERROR_MODULE_PROFILE = 19;

  public static final int NS_ERROR_MODULE_LDAP = 20;

  public static final int NS_ERROR_MODULE_SECURITY = 21;

  public static final int NS_ERROR_MODULE_DOM_XPATH = 22;

  public static final int NS_ERROR_MODULE_URILOADER = 24;

  public static final int NS_ERROR_MODULE_CONTENT = 25;

  public static final int NS_ERROR_MODULE_PYXPCOM = 26;

  public static final int NS_ERROR_MODULE_XSLT = 27;

  public static final int NS_ERROR_MODULE_IPC = 28;

  public static final int NS_ERROR_MODULE_SVG = 29;

  public static final int NS_ERROR_MODULE_STORAGE = 30;

  public static final int NS_ERROR_MODULE_SCHEMA = 31;

  public static final int NS_ERROR_MODULE_DOM_FILE = 32;

  public static final int NS_ERROR_MODULE_DOM_INDEXEDDB = 33;

  public static final int NS_ERROR_MODULE_DOM_FILEHANDLE = 34;

  public static final int NS_ERROR_MODULE_SIGNED_JAR = 35;

  public static final int NS_ERROR_MODULE_DOM_FILESYSTEM = 36;

  public static final int NS_ERROR_MODULE_DOM_BLUETOOTH = 37;

  public static final int NS_ERROR_MODULE_SIGNED_APP = 38;

  public static final int NS_ERROR_MODULE_DOM_ANIM = 39;

  public static final int NS_ERROR_MODULE_DOM_PUSH = 40;

  public static final int NS_ERROR_MODULE_DOM_MEDIA = 41;

  public static final int NS_ERROR_MODULE_URL_CLASSIFIER = 42;

  public static final int NS_ERROR_MODULE_ERRORRESULT = 43;

  public static final int NS_ERROR_MODULE_WIN32 = 44;

  public static final int NS_ERROR_MODULE_WDBA = 45;

  public static final int NS_ERROR_MODULE_DOM_QM = 46;

  public static final int NS_ERROR_MODULE_CLIPBOARD = 47;

  public static final int NS_ERROR_MODULE_DOM_SERIAL = 48;

  public static final int NS_ERROR_MODULE_GENERAL = 51;



  public static final long NS_OK = 0x0L;

  public static final long NS_ERROR_BASE = 0xC1F30000L;

  public static final long NS_ERROR_NOT_INITIALIZED = 0xC1F30001L;

  public static final long NS_ERROR_ALREADY_INITIALIZED = 0xC1F30002L;

  public static final long NS_ERROR_NOT_IMPLEMENTED = 0x80004001L;

  public static final long NS_NOINTERFACE = 0x80004002L;

  public static final long NS_ERROR_NO_INTERFACE = 0x80004002L;

  public static final long NS_ERROR_ABORT = 0x80004004L;

  public static final long NS_ERROR_FAILURE = 0x80004005L;

  public static final long NS_ERROR_UNEXPECTED = 0x8000FFFFL;

  public static final long NS_ERROR_OUT_OF_MEMORY = 0x8007000EL;

  public static final long NS_ERROR_ILLEGAL_VALUE = 0x80070057L;

  public static final long NS_ERROR_INVALID_ARG = 0x80070057L;

  public static final long NS_ERROR_INVALID_POINTER = 0x80070057L;

  public static final long NS_ERROR_NULL_POINTER = 0x80070057L;

  public static final long NS_ERROR_NOT_AVAILABLE = 0x80040111L;

  public static final long NS_ERROR_FACTORY_NOT_REGISTERED = 0x80040154L;

  public static final long NS_ERROR_FACTORY_REGISTER_AGAIN = 0x80040155L;

  public static final long NS_ERROR_FACTORY_NOT_LOADED = 0x800401F8L;

  public static final long NS_ERROR_FACTORY_NO_SIGNATURE_SUPPORT = 0xC1F30101L;

  public static final long NS_ERROR_FACTORY_EXISTS = 0xC1F30100L;

  public static final long NS_ERROR_CANNOT_CONVERT_DATA = 0x80460001L;

  public static final long NS_ERROR_OBJECT_IS_IMMUTABLE = 0x80460002L;

  public static final long NS_ERROR_LOSS_OF_SIGNIFICANT_DATA = 0x80460003L;

  public static final long NS_ERROR_NOT_SAME_THREAD = 0x80460004L;

  public static final long NS_ERROR_ILLEGAL_DURING_SHUTDOWN = 0x8046001EL;

  public static final long NS_ERROR_SERVICE_NOT_AVAILABLE = 0x80460016L;

  public static final long NS_ERROR_OMNIJAR_CORRUPT = 0x80460028L;

  public static final long NS_ERROR_OMNIJAR_OR_DIR_MISSING = 0x80460029L;

  public static final long NS_SUCCESS_LOSS_OF_INSIGNIFICANT_DATA = 0x460001L;

  public static final long NS_SUCCESS_INTERRUPTED_TRAVERSE = 0x460002L;

  public static final long NS_BASE_STREAM_CLOSED = 0x80470002L;

  public static final long NS_BASE_STREAM_OSERROR = 0x80470003L;

  public static final long NS_BASE_STREAM_ILLEGAL_ARGS = 0x80470004L;

  public static final long NS_BASE_STREAM_NO_CONVERTER = 0x80470005L;

  public static final long NS_BASE_STREAM_BAD_CONVERSION = 0x80470006L;

  public static final long NS_BASE_STREAM_WOULD_BLOCK = 0x80470007L;

  public static final long NS_ERROR_GFX_PRINTER_NO_PRINTER_AVAILABLE = 0x80480001L;

  public static final long NS_ERROR_GFX_PRINTER_NAME_NOT_FOUND = 0x80480002L;

  public static final long NS_ERROR_GFX_PRINTER_COULD_NOT_OPEN_FILE = 0x80480003L;

  public static final long NS_ERROR_GFX_PRINTER_STARTDOC = 0x80480004L;

  public static final long NS_ERROR_GFX_PRINTER_ENDDOC = 0x80480005L;

  public static final long NS_ERROR_GFX_PRINTER_STARTPAGE = 0x80480006L;

  public static final long NS_ERROR_GFX_PRINTER_DOC_IS_BUSY = 0x80480007L;

  public static final long NS_ERROR_GFX_CMAP_MALFORMED = 0x80480033L;

  public static final long NS_SUCCESS_EVENT_CONSUMED = 0x490001L;

  public static final long NS_BINDING_SUCCEEDED = 0x0L;

  public static final long NS_BINDING_FAILED = 0x804B0001L;

  public static final long NS_BINDING_ABORTED = 0x804B0002L;

  public static final long NS_BINDING_REDIRECTED = 0x804B0003L;

  public static final long NS_BINDING_RETARGETED = 0x804B0004L;

  public static final long NS_ERROR_MALFORMED_URI = 0x804B000AL;

  public static final long NS_ERROR_IN_PROGRESS = 0x804B000FL;

  public static final long NS_ERROR_NO_CONTENT = 0x804B0011L;

  public static final long NS_ERROR_UNKNOWN_PROTOCOL = 0x804B0012L;

  public static final long NS_ERROR_INVALID_CONTENT_ENCODING = 0x804B001BL;

  public static final long NS_ERROR_CORRUPTED_CONTENT = 0x804B001DL;

  public static final long NS_ERROR_INVALID_SIGNATURE = 0x804B003AL;

  public static final long NS_ERROR_FIRST_HEADER_FIELD_COMPONENT_EMPTY = 0x804B0022L;

  public static final long NS_ERROR_ALREADY_OPENED = 0x804B0049L;

  public static final long NS_ERROR_ALREADY_CONNECTED = 0x804B000BL;

  public static final long NS_ERROR_NOT_CONNECTED = 0x804B000CL;

  public static final long NS_ERROR_CONNECTION_REFUSED = 0x804B000DL;

  public static final long NS_ERROR_NET_TIMEOUT = 0x804B000EL;

  public static final long NS_ERROR_OFFLINE = 0x804B0010L;

  public static final long NS_ERROR_PORT_ACCESS_NOT_ALLOWED = 0x804B0013L;

  public static final long NS_ERROR_NET_RESET = 0x804B0014L;

  public static final long NS_ERROR_NET_ERROR_RESPONSE = 0x804B0023L;

  public static final long NS_ERROR_NET_EMPTY_RESPONSE = 0x804B0024L;

  public static final long NS_ERROR_NET_INTERRUPT = 0x804B0047L;

  public static final long NS_ERROR_PROXY_CONNECTION_REFUSED = 0x804B0048L;

  public static final long NS_ERROR_NET_PARTIAL_TRANSFER = 0x804B004CL;

  public static final long NS_ERROR_NET_INADEQUATE_SECURITY = 0x804B0052L;

  public static final long NS_ERROR_NET_HTTP2_SENT_GOAWAY = 0x804B0053L;

  public static final long NS_ERROR_NET_HTTP3_PROTOCOL_ERROR = 0x804B0054L;

  public static final long NS_ERROR_NET_TIMEOUT_EXTERNAL = 0x804B0055L;

  public static final long NS_ERROR_HTTPS_ONLY = 0x804B0056L;

  public static final long NS_ERROR_WEBSOCKET_CONNECTION_REFUSED = 0x804B0057L;

  public static final long NS_ERROR_NON_LOCAL_CONNECTION_REFUSED = 0x804B0058L;

  public static final long NS_ERROR_BAD_HSTS_CERT = 0x804B0059L;

  public static final long NS_ERROR_PARSING_HTTP_STATUS_LINE = 0x804B005AL;

  public static final long NS_ERROR_BASIC_HTTP_AUTH_DISABLED = 0x804B005CL;

  public static final long NS_ERROR_LOCAL_NETWORK_ACCESS_DENIED = 0x804B005DL;

  public static final long NS_ERROR_HTTP2_FALLBACK_TO_HTTP1 = 0x804B005EL;

  public static final long NS_ERROR_OS_LOCAL_NETWORK_ACCESS_DENIED = 0x804B005FL;

  public static final long NS_ERROR_NOT_RESUMABLE = 0x804B0019L;

  public static final long NS_ERROR_REDIRECT_LOOP = 0x804B001FL;

  public static final long NS_ERROR_ENTITY_CHANGED = 0x804B0020L;

  public static final long NS_ERROR_UNSAFE_CONTENT_TYPE = 0x804B004AL;

  public static final long NS_ERROR_LOAD_SHOWED_ERRORPAGE = 0x804B004DL;

  public static final long NS_ERROR_DOCSHELL_DYING = 0x804B004EL;

  public static final long NS_ERROR_DOCUMENT_LOAD_LISTENER_NO_PARENT_CHANNEL = 0x804B004FL;

  public static final long NS_ERROR_UNKNOWN_HOST = 0x804B001EL;

  public static final long NS_ERROR_DNS_LOOKUP_QUEUE_FULL = 0x804B0021L;

  public static final long NS_ERROR_UNKNOWN_PROXY_HOST = 0x804B002AL;

  public static final long NS_ERROR_DEFINITIVE_UNKNOWN_HOST = 0x804B002BL;

  public static final long NS_ERROR_UNKNOWN_SOCKET_TYPE = 0x804B0033L;

  public static final long NS_ERROR_SOCKET_CREATE_FAILED = 0x804B0034L;

  public static final long NS_ERROR_SOCKET_ADDRESS_NOT_SUPPORTED = 0x804B0035L;

  public static final long NS_ERROR_SOCKET_ADDRESS_IN_USE = 0x804B0036L;

  public static final long NS_ERROR_CACHE_KEY_NOT_FOUND = 0x804B003DL;

  public static final long NS_ERROR_CACHE_DATA_IS_STREAM = 0x804B003EL;

  public static final long NS_ERROR_CACHE_DATA_IS_NOT_STREAM = 0x804B003FL;

  public static final long NS_ERROR_CACHE_WAIT_FOR_VALIDATION = 0x804B0040L;

  public static final long NS_ERROR_CACHE_ENTRY_DOOMED = 0x804B0041L;

  public static final long NS_ERROR_CACHE_READ_ACCESS_DENIED = 0x804B0042L;

  public static final long NS_ERROR_CACHE_WRITE_ACCESS_DENIED = 0x804B0043L;

  public static final long NS_ERROR_CACHE_IN_USE = 0x804B0044L;

  public static final long NS_ERROR_DOCUMENT_NOT_CACHED = 0x804B0046L;

  public static final long NS_ERROR_INSUFFICIENT_DOMAIN_LEVELS = 0x804B0050L;

  public static final long NS_ERROR_HOST_IS_IP_ADDRESS = 0x804B0051L;

  public static final long NS_SUCCESS_ADOPTED_DATA = 0x4B005AL;

  public static final long NS_SUCCESS_AUTH_FINISHED = 0x4B0028L;

  public static final long NS_NET_STATUS_READING = 0x4B0008L;

  public static final long NS_NET_STATUS_WRITING = 0x4B0009L;

  public static final long NS_NET_STATUS_RESOLVING_HOST = 0x4B0003L;

  public static final long NS_NET_STATUS_RESOLVED_HOST = 0x4B000BL;

  public static final long NS_NET_STATUS_CONNECTING_TO = 0x4B0007L;

  public static final long NS_NET_STATUS_CONNECTED_TO = 0x4B0004L;

  public static final long NS_NET_STATUS_TLS_HANDSHAKE_STARTING = 0x4B000CL;

  public static final long NS_NET_STATUS_TLS_HANDSHAKE_ENDED = 0x4B000DL;

  public static final long NS_NET_STATUS_SENDING_TO = 0x4B0005L;

  public static final long NS_NET_STATUS_WAITING_FOR = 0x4B000AL;

  public static final long NS_NET_STATUS_RECEIVING_FROM = 0x4B0006L;

  public static final long NS_ERROR_INTERCEPTION_FAILED = 0x804B0064L;

  public static final long NS_ERROR_WEBTRANSPORT_SESSION_LIMIT_EXCEEDED = 0x804B00C7L;

  public static final long NS_ERROR_WEBTRANSPORT_CODE_BASE = 0x804B00C8L;

  public static final long NS_ERROR_WEBTRANSPORT_CODE_END = 0x804B01C7L;

  public static final long NS_ERROR_PROXY_CODE_BASE = 0x804B03E8L;

  public static final long NS_ERROR_PROXY_MULTIPLE_CHOICES = 0x804B0514L;

  public static final long NS_ERROR_PROXY_MOVED_PERMANENTLY = 0x804B0515L;

  public static final long NS_ERROR_PROXY_FOUND = 0x804B0516L;

  public static final long NS_ERROR_PROXY_SEE_OTHER = 0x804B0517L;

  public static final long NS_ERROR_PROXY_NOT_MODIFIED = 0x804B0518L;

  public static final long NS_ERROR_PROXY_TEMPORARY_REDIRECT = 0x804B051BL;

  public static final long NS_ERROR_PROXY_PERMANENT_REDIRECT = 0x804B051CL;

  public static final long NS_ERROR_PROXY_BAD_REQUEST = 0x804B0578L;

  public static final long NS_ERROR_PROXY_UNAUTHORIZED = 0x804B0579L;

  public static final long NS_ERROR_PROXY_PAYMENT_REQUIRED = 0x804B057AL;

  public static final long NS_ERROR_PROXY_FORBIDDEN = 0x804B057BL;

  public static final long NS_ERROR_PROXY_NOT_FOUND = 0x804B057CL;

  public static final long NS_ERROR_PROXY_METHOD_NOT_ALLOWED = 0x804B057DL;

  public static final long NS_ERROR_PROXY_NOT_ACCEPTABLE = 0x804B057EL;

  public static final long NS_ERROR_PROXY_AUTHENTICATION_FAILED = 0x804B057FL;

  public static final long NS_ERROR_PROXY_REQUEST_TIMEOUT = 0x804B0580L;

  public static final long NS_ERROR_PROXY_CONFLICT = 0x804B0581L;

  public static final long NS_ERROR_PROXY_GONE = 0x804B0582L;

  public static final long NS_ERROR_PROXY_LENGTH_REQUIRED = 0x804B0583L;

  public static final long NS_ERROR_PROXY_PRECONDITION_FAILED = 0x804B0584L;

  public static final long NS_ERROR_PROXY_REQUEST_ENTITY_TOO_LARGE = 0x804B0585L;

  public static final long NS_ERROR_PROXY_REQUEST_URI_TOO_LONG = 0x804B0586L;

  public static final long NS_ERROR_PROXY_UNSUPPORTED_MEDIA_TYPE = 0x804B0587L;

  public static final long NS_ERROR_PROXY_REQUESTED_RANGE_NOT_SATISFIABLE = 0x804B0588L;

  public static final long NS_ERROR_PROXY_EXPECTATION_FAILED = 0x804B0589L;

  public static final long NS_ERROR_PROXY_MISDIRECTED_REQUEST = 0x804B058DL;

  public static final long NS_ERROR_PROXY_TOO_EARLY = 0x804B0591L;

  public static final long NS_ERROR_PROXY_UPGRADE_REQUIRED = 0x804B0592L;

  public static final long NS_ERROR_PROXY_PRECONDITION_REQUIRED = 0x804B0594L;

  public static final long NS_ERROR_PROXY_TOO_MANY_REQUESTS = 0x804B0595L;

  public static final long NS_ERROR_PROXY_REQUEST_HEADER_FIELDS_TOO_LARGE = 0x804B0597L;

  public static final long NS_ERROR_PROXY_UNAVAILABLE_FOR_LEGAL_REASONS = 0x804B05ABL;

  public static final long NS_ERROR_PROXY_INTERNAL_SERVER_ERROR = 0x804B05DCL;

  public static final long NS_ERROR_PROXY_NOT_IMPLEMENTED = 0x804B05DDL;

  public static final long NS_ERROR_PROXY_BAD_GATEWAY = 0x804B05DEL;

  public static final long NS_ERROR_PROXY_SERVICE_UNAVAILABLE = 0x804B05DFL;

  public static final long NS_ERROR_PROXY_GATEWAY_TIMEOUT = 0x804B05E0L;

  public static final long NS_ERROR_PROXY_VERSION_NOT_SUPPORTED = 0x804B05E1L;

  public static final long NS_ERROR_PROXY_VARIANT_ALSO_NEGOTIATES = 0x804B05E2L;

  public static final long NS_ERROR_PROXY_NOT_EXTENDED = 0x804B05E6L;

  public static final long NS_ERROR_PROXY_NETWORK_AUTHENTICATION_REQUIRED = 0x804B05E7L;

  public static final long NS_ERROR_PLUGINS_PLUGINSNOTCHANGED = 0x804C03E8L;

  public static final long NS_ERROR_PLUGIN_DISABLED = 0x804C03E9L;

  public static final long NS_ERROR_PLUGIN_TIME_RANGE_NOT_SUPPORTED = 0x804C03EBL;

  public static final long NS_ERROR_PLUGIN_CLICKTOPLAY = 0x804C03ECL;

  public static final long NS_OK_PARSE_SHEET = 0x4D0001L;

  public static final long NS_ERROR_HTMLPARSER_CONTINUE = 0x0L;

  public static final long NS_ERROR_HTMLPARSER_EOF = 0x804E03E8L;

  public static final long NS_ERROR_HTMLPARSER_BADURL = 0x804E03EDL;

  public static final long NS_ERROR_HTMLPARSER_INVALIDPARSERCONTEXT = 0x804E03EEL;

  public static final long NS_ERROR_HTMLPARSER_INTERRUPTED = 0x804E03EFL;

  public static final long NS_ERROR_HTMLPARSER_BLOCK = 0x804E03F0L;

  public static final long NS_ERROR_HTMLPARSER_UNRESOLVEDDTD = 0x804E03F3L;

  public static final long NS_ERROR_HTMLPARSER_STOPPARSING = 0x804E03F7L;

  public static final long NS_ERROR_HTMLPARSER_HIERARCHYTOODEEP = 0x804E03F9L;

  public static final long NS_RDF_ASSERTION_ACCEPTED = 0x0L;

  public static final long NS_RDF_NO_VALUE = 0x4F0002L;

  public static final long NS_RDF_ASSERTION_REJECTED = 0x4F0003L;

  public static final long NS_RDF_STOP_VISIT = 0x4F0004L;

  public static final long NS_ERROR_UCONV_NOCONV = 0x80500001L;

  public static final long NS_ERROR_UDEC_ILLEGALINPUT = 0x8050000EL;

  public static final long NS_OK_HAD_REPLACEMENTS = 0x500003L;

  public static final long NS_OK_UDEC_MOREINPUT = 0x50000CL;

  public static final long NS_OK_UDEC_MOREOUTPUT = 0x50000DL;

  public static final long NS_OK_UENC_MOREOUTPUT = 0x500022L;

  public static final long NS_ERROR_UENC_NOMAPPING = 0x500023L;

  public static final long NS_ERROR_ILLEGAL_INPUT = 0x8050000EL;

  public static final long NS_ERROR_FILE_UNRECOGNIZED_PATH = 0x80520001L;

  public static final long NS_ERROR_FILE_UNRESOLVABLE_SYMLINK = 0x80520002L;

  public static final long NS_ERROR_FILE_EXECUTION_FAILED = 0x80520003L;

  public static final long NS_ERROR_FILE_UNKNOWN_TYPE = 0x80520004L;

  public static final long NS_ERROR_FILE_DESTINATION_NOT_DIR = 0x80520005L;

  public static final long NS_ERROR_FILE_COPY_OR_MOVE_FAILED = 0x80520007L;

  public static final long NS_ERROR_FILE_ALREADY_EXISTS = 0x80520008L;

  public static final long NS_ERROR_FILE_INVALID_PATH = 0x80520009L;

  public static final long NS_ERROR_FILE_CORRUPTED = 0x8052000BL;

  public static final long NS_ERROR_FILE_NOT_DIRECTORY = 0x8052000CL;

  public static final long NS_ERROR_FILE_IS_DIRECTORY = 0x8052000DL;

  public static final long NS_ERROR_FILE_IS_LOCKED = 0x8052000EL;

  public static final long NS_ERROR_FILE_TOO_BIG = 0x8052000FL;

  public static final long NS_ERROR_FILE_NO_DEVICE_SPACE = 0x80520010L;

  public static final long NS_ERROR_FILE_NAME_TOO_LONG = 0x80520011L;

  public static final long NS_ERROR_FILE_NOT_FOUND = 0x80520012L;

  public static final long NS_ERROR_FILE_READ_ONLY = 0x80520013L;

  public static final long NS_ERROR_FILE_DIR_NOT_EMPTY = 0x80520014L;

  public static final long NS_ERROR_FILE_ACCESS_DENIED = 0x80520015L;

  public static final long NS_ERROR_FILE_FS_CORRUPTED = 0x80520016L;

  public static final long NS_ERROR_FILE_DEVICE_FAILURE = 0x80520017L;

  public static final long NS_ERROR_FILE_DEVICE_TEMPORARY_FAILURE = 0x80520018L;

  public static final long NS_ERROR_FILE_INVALID_HANDLE = 0x80520019L;

  public static final long NS_SUCCESS_FILE_DIRECTORY_EMPTY = 0x520001L;

  public static final long NS_SUCCESS_AGGREGATE_RESULT = 0x520002L;

  public static final long NS_ERROR_DOM_INDEX_SIZE_ERR = 0x80530001L;

  public static final long NS_ERROR_DOM_HIERARCHY_REQUEST_ERR = 0x80530003L;

  public static final long NS_ERROR_DOM_WRONG_DOCUMENT_ERR = 0x80530004L;

  public static final long NS_ERROR_DOM_INVALID_CHARACTER_ERR = 0x80530005L;

  public static final long NS_ERROR_DOM_NO_MODIFICATION_ALLOWED_ERR = 0x80530007L;

  public static final long NS_ERROR_DOM_NOT_FOUND_ERR = 0x80530008L;

  public static final long NS_ERROR_DOM_NOT_SUPPORTED_ERR = 0x80530009L;

  public static final long NS_ERROR_DOM_INUSE_ATTRIBUTE_ERR = 0x8053000AL;

  public static final long NS_ERROR_DOM_INVALID_STATE_ERR = 0x8053000BL;

  public static final long NS_ERROR_DOM_SYNTAX_ERR = 0x8053000CL;

  public static final long NS_ERROR_DOM_INVALID_MODIFICATION_ERR = 0x8053000DL;

  public static final long NS_ERROR_DOM_NAMESPACE_ERR = 0x8053000EL;

  public static final long NS_ERROR_DOM_INVALID_ACCESS_ERR = 0x8053000FL;

  public static final long NS_ERROR_DOM_TYPE_MISMATCH_ERR = 0x80530011L;

  public static final long NS_ERROR_DOM_SECURITY_ERR = 0x80530012L;

  public static final long NS_ERROR_DOM_NETWORK_ERR = 0x80530013L;

  public static final long NS_ERROR_DOM_ABORT_ERR = 0x80530014L;

  public static final long NS_ERROR_DOM_URL_MISMATCH_ERR = 0x80530015L;

  public static final long NS_ERROR_DOM_QUOTA_EXCEEDED_ERR = 0x80530016L;

  public static final long NS_ERROR_DOM_TIMEOUT_ERR = 0x80530017L;

  public static final long NS_ERROR_DOM_INVALID_NODE_TYPE_ERR = 0x80530018L;

  public static final long NS_ERROR_DOM_DATA_CLONE_ERR = 0x80530019L;

  public static final long NS_ERROR_DOM_ENCODING_NOT_SUPPORTED_ERR = 0x8053001CL;

  public static final long NS_ERROR_DOM_UNKNOWN_ERR = 0x8053001EL;

  public static final long NS_ERROR_DOM_DATA_ERR = 0x8053001FL;

  public static final long NS_ERROR_DOM_OPERATION_ERR = 0x80530020L;

  public static final long NS_ERROR_DOM_NOT_ALLOWED_ERR = 0x80530021L;

  public static final long NS_ERROR_DOM_WRONG_TYPE_ERR = 0x805303EAL;

  public static final long NS_ERROR_DOM_NOT_NUMBER_ERR = 0x805303EDL;

  public static final long NS_ERROR_DOM_PROP_ACCESS_DENIED = 0x805303F2L;

  public static final long NS_ERROR_DOM_XPCONNECT_ACCESS_DENIED = 0x805303F3L;

  public static final long NS_ERROR_DOM_BAD_URI = 0x805303F4L;

  public static final long NS_ERROR_DOM_RETVAL_UNDEFINED = 0x805303F5L;

  public static final long NS_ERROR_UNCATCHABLE_EXCEPTION = 0x805303F7L;

  public static final long NS_ERROR_DOM_MALFORMED_URI = 0x805303F8L;

  public static final long NS_ERROR_DOM_INVALID_HEADER_NAME = 0x805303F9L;

  public static final long NS_ERROR_DOM_INVALID_STATE_XHR_HAS_INVALID_CONTEXT = 0x805303FAL;

  public static final long NS_ERROR_DOM_JS_DECODING_ERROR = 0x80530402L;

  public static final long NS_ERROR_DOM_IMAGE_INACTIVE_DOCUMENT = 0x80530403L;

  public static final long NS_ERROR_DOM_IMAGE_INVALID_REQUEST = 0x80530404L;

  public static final long NS_ERROR_DOM_IMAGE_BROKEN = 0x80530405L;

  public static final long NS_ERROR_DOM_CORP_FAILED = 0x8053040CL;

  public static final long NS_ERROR_DOM_BAD_CROSS_ORIGIN_URI = 0x8053040DL;

  public static final long NS_ERROR_RECURSIVE_DOCUMENT_LOAD = 0x8053040EL;

  public static final long NS_ERROR_DOM_WEBEXT_CONTENT_SCRIPT_URI = 0x8053040FL;

  public static final long NS_ERROR_DOM_COEP_FAILED = 0x80530410L;

  public static final long NS_ERROR_DOM_COOP_FAILED = 0x80530411L;

  public static final long NS_ERROR_DOM_INVALID_HEADER_VALUE = 0x80530412L;

  public static final long NS_SUCCESS_DOM_NO_OPERATION = 0x530001L;

  public static final long NS_SUCCESS_DOM_SCRIPT_EVALUATION_THREW = 0x530002L;

  public static final long NS_SUCCESS_DOM_SCRIPT_EVALUATION_THREW_UNCATCHABLE = 0x530003L;

  public static final long NS_IMAGELIB_ERROR_FAILURE = 0x80540005L;

  public static final long NS_IMAGELIB_ERROR_NO_DECODER = 0x80540006L;

  public static final long NS_IMAGELIB_ERROR_NOT_FINISHED = 0x80540007L;

  public static final long NS_IMAGELIB_ERROR_NO_ENCODER = 0x80540009L;

  public static final long NS_ERROR_EDITOR_DESTROYED = 0x80560001L;

  public static final long NS_ERROR_EDITOR_UNEXPECTED_DOM_TREE = 0x80560002L;

  public static final long NS_ERROR_EDITOR_ACTION_CANCELED = 0x80560003L;

  public static final long NS_ERROR_EDITOR_NO_EDITABLE_RANGE = 0x80560004L;

  public static final long NS_ERROR_EDITOR_NO_DELETABLE_RANGE = 0x80560005L;

  public static final long NS_SUCCESS_EDITOR_ELEMENT_NOT_FOUND = 0x560001L;

  public static final long NS_SUCCESS_EDITOR_FOUND_TARGET = 0x560002L;

  public static final long NS_SUCCESS_EDITOR_BUT_IGNORED_TRIVIAL_ERROR = 0x560003L;

  public static final long NS_ERROR_XPC_NOT_ENOUGH_ARGS = 0x80570001L;

  public static final long NS_ERROR_XPC_NEED_OUT_OBJECT = 0x80570002L;

  public static final long NS_ERROR_XPC_CANT_SET_OUT_VAL = 0x80570003L;

  public static final long NS_ERROR_XPC_NATIVE_RETURNED_FAILURE = 0x80570004L;

  public static final long NS_ERROR_XPC_CANT_GET_INTERFACE_INFO = 0x80570005L;

  public static final long NS_ERROR_XPC_CANT_GET_PARAM_IFACE_INFO = 0x80570006L;

  public static final long NS_ERROR_XPC_CANT_GET_METHOD_INFO = 0x80570007L;

  public static final long NS_ERROR_XPC_UNEXPECTED = 0x80570008L;

  public static final long NS_ERROR_XPC_BAD_CONVERT_JS = 0x80570009L;

  public static final long NS_ERROR_XPC_BAD_CONVERT_NATIVE = 0x8057000AL;

  public static final long NS_ERROR_XPC_BAD_CONVERT_JS_NULL_REF = 0x8057000BL;

  public static final long NS_ERROR_XPC_BAD_OP_ON_WN_PROTO = 0x8057000CL;

  public static final long NS_ERROR_XPC_CANT_CONVERT_WN_TO_FUN = 0x8057000DL;

  public static final long NS_ERROR_XPC_CANT_DEFINE_PROP_ON_WN = 0x8057000EL;

  public static final long NS_ERROR_XPC_CANT_WATCH_WN_STATIC = 0x8057000FL;

  public static final long NS_ERROR_XPC_CANT_EXPORT_WN_STATIC = 0x80570010L;

  public static final long NS_ERROR_XPC_SCRIPTABLE_CALL_FAILED = 0x80570011L;

  public static final long NS_ERROR_XPC_SCRIPTABLE_CTOR_FAILED = 0x80570012L;

  public static final long NS_ERROR_XPC_CANT_CALL_WO_SCRIPTABLE = 0x80570013L;

  public static final long NS_ERROR_XPC_CANT_CTOR_WO_SCRIPTABLE = 0x80570014L;

  public static final long NS_ERROR_XPC_CI_RETURNED_FAILURE = 0x80570015L;

  public static final long NS_ERROR_XPC_GS_RETURNED_FAILURE = 0x80570016L;

  public static final long NS_ERROR_XPC_BAD_CID = 0x80570017L;

  public static final long NS_ERROR_XPC_BAD_IID = 0x80570018L;

  public static final long NS_ERROR_XPC_CANT_CREATE_WN = 0x80570019L;

  public static final long NS_ERROR_XPC_JS_THREW_EXCEPTION = 0x8057001AL;

  public static final long NS_ERROR_XPC_JS_THREW_NATIVE_OBJECT = 0x8057001BL;

  public static final long NS_ERROR_XPC_JS_THREW_JS_OBJECT = 0x8057001CL;

  public static final long NS_ERROR_XPC_JS_THREW_NULL = 0x8057001DL;

  public static final long NS_ERROR_XPC_JS_THREW_STRING = 0x8057001EL;

  public static final long NS_ERROR_XPC_JS_THREW_NUMBER = 0x8057001FL;

  public static final long NS_ERROR_XPC_JAVASCRIPT_ERROR = 0x80570020L;

  public static final long NS_ERROR_XPC_JAVASCRIPT_ERROR_WITH_DETAILS = 0x80570021L;

  public static final long NS_ERROR_XPC_CANT_CONVERT_PRIMITIVE_TO_ARRAY = 0x80570022L;

  public static final long NS_ERROR_XPC_CANT_CONVERT_OBJECT_TO_ARRAY = 0x80570023L;

  public static final long NS_ERROR_XPC_NOT_ENOUGH_ELEMENTS_IN_ARRAY = 0x80570024L;

  public static final long NS_ERROR_XPC_CANT_GET_ARRAY_INFO = 0x80570025L;

  public static final long NS_ERROR_XPC_NOT_ENOUGH_CHARS_IN_STRING = 0x80570026L;

  public static final long NS_ERROR_XPC_SECURITY_MANAGER_VETO = 0x80570027L;

  public static final long NS_ERROR_XPC_INTERFACE_NOT_SCRIPTABLE = 0x80570028L;

  public static final long NS_ERROR_XPC_INTERFACE_NOT_FROM_NSISUPPORTS = 0x80570029L;

  public static final long NS_ERROR_XPC_CANT_SET_READ_ONLY_CONSTANT = 0x8057002BL;

  public static final long NS_ERROR_XPC_CANT_SET_READ_ONLY_ATTRIBUTE = 0x8057002CL;

  public static final long NS_ERROR_XPC_CANT_SET_READ_ONLY_METHOD = 0x8057002DL;

  public static final long NS_ERROR_XPC_CANT_ADD_PROP_TO_WRAPPED_NATIVE = 0x8057002EL;

  public static final long NS_ERROR_XPC_CALL_TO_SCRIPTABLE_FAILED = 0x8057002FL;

  public static final long NS_ERROR_XPC_JSOBJECT_HAS_NO_FUNCTION_NAMED = 0x80570030L;

  public static final long NS_ERROR_XPC_BAD_ID_STRING = 0x80570031L;

  public static final long NS_ERROR_XPC_BAD_INITIALIZER_NAME = 0x80570032L;

  public static final long NS_ERROR_XPC_HAS_BEEN_SHUTDOWN = 0x80570033L;

  public static final long NS_ERROR_XPC_CANT_MODIFY_PROP_ON_WN = 0x80570034L;

  public static final long NS_ERROR_XPC_BAD_CONVERT_JS_ZERO_ISNOT_NULL = 0x80570035L;

  public static final long NS_ERROR_LAUNCHED_CHILD_PROCESS = 0x805800C8L;

  public static final long NS_ERROR_SHOW_PROFILE_MANAGER = 0x805800C9L;

  public static final long NS_ERROR_DATABASE_CHANGED = 0x805800CAL;

  public static final long NS_ERROR_XFO_VIOLATION = 0x805A0060L;

  public static final long NS_ERROR_CSP_FORM_ACTION_VIOLATION = 0x805A0061L;

  public static final long NS_ERROR_CSP_FRAME_ANCESTOR_VIOLATION = 0x805A0062L;

  public static final long NS_ERROR_SRI_CORRUPT = 0x805A00C8L;

  public static final long NS_ERROR_SRI_NOT_ELIGIBLE = 0x805A00C9L;

  public static final long NS_ERROR_SRI_UNEXPECTED_HASH_TYPE = 0x805A00CAL;

  public static final long NS_ERROR_SRI_IMPORT = 0x805A00CBL;

  public static final long NS_ERROR_CMS_VERIFY_NOT_SIGNED = 0x805A0400L;

  public static final long NS_ERROR_CMS_VERIFY_NO_CONTENT_INFO = 0x805A0401L;

  public static final long NS_ERROR_CMS_VERIFY_BAD_DIGEST = 0x805A0402L;

  public static final long NS_ERROR_CMS_VERIFY_NOCERT = 0x805A0404L;

  public static final long NS_ERROR_CMS_VERIFY_UNTRUSTED = 0x805A0405L;

  public static final long NS_ERROR_CMS_VERIFY_ERROR_UNVERIFIED = 0x805A0407L;

  public static final long NS_ERROR_CMS_VERIFY_ERROR_PROCESSING = 0x805A0408L;

  public static final long NS_ERROR_CMS_VERIFY_BAD_SIGNATURE = 0x805A0409L;

  public static final long NS_ERROR_CMS_VERIFY_DIGEST_MISMATCH = 0x805A040AL;

  public static final long NS_ERROR_CMS_VERIFY_UNKNOWN_ALGO = 0x805A040BL;

  public static final long NS_ERROR_CMS_VERIFY_UNSUPPORTED_ALGO = 0x805A040CL;

  public static final long NS_ERROR_CMS_VERIFY_MALFORMED_SIGNATURE = 0x805A040DL;

  public static final long NS_ERROR_CMS_VERIFY_HEADER_MISMATCH = 0x805A040EL;

  public static final long NS_ERROR_CMS_VERIFY_NOT_YET_ATTEMPTED = 0x805A040FL;

  public static final long NS_ERROR_CMS_VERIFY_CERT_WITHOUT_ADDRESS = 0x805A0410L;

  public static final long NS_ERROR_CMS_ENCRYPT_NO_BULK_ALG = 0x805A0420L;

  public static final long NS_ERROR_CMS_ENCRYPT_INCOMPLETE = 0x805A0421L;

  public static final long NS_ERROR_WONT_HANDLE_CONTENT = 0x805D0001L;

  public static final long NS_ERROR_MALWARE_URI = 0x805D001EL;

  public static final long NS_ERROR_PHISHING_URI = 0x805D001FL;

  public static final long NS_ERROR_TRACKING_URI = 0x805D0022L;

  public static final long NS_ERROR_UNWANTED_URI = 0x805D0023L;

  public static final long NS_ERROR_BLOCKED_URI = 0x805D0025L;

  public static final long NS_ERROR_HARMFUL_URI = 0x805D0026L;

  public static final long NS_ERROR_FINGERPRINTING_URI = 0x805D0029L;

  public static final long NS_ERROR_CRYPTOMINING_URI = 0x805D002AL;

  public static final long NS_ERROR_SOCIALTRACKING_URI = 0x805D002BL;

  public static final long NS_ERROR_EMAILTRACKING_URI = 0x805D002CL;

  public static final long NS_ERROR_RESTRICTED_CONTENT = 0x805D002DL;

  public static final long NS_ERROR_HARMFULADDON_URI = 0x805D002EL;

  public static final long NS_ERROR_SAVE_LINK_AS_TIMEOUT = 0x805D0020L;

  public static final long NS_ERROR_PARSED_DATA_CACHED = 0x805D0021L;

  public static final long NS_BINDING_CANCELLED_OLD_LOAD = 0x805D0027L;

  public static final long NS_ERROR_CONTENT_BLOCKED = 0x805E0006L;

  public static final long NS_ERROR_CONTENT_BLOCKED_SHOW_ALT = 0x805E0007L;

  public static final long NS_PROPTABLE_PROP_NOT_THERE = 0x805E000AL;

  public static final long NS_ERROR_CONTENT_CRASHED = 0x805E0010L;

  public static final long NS_ERROR_FRAME_CRASHED = 0x805E000EL;

  public static final long NS_ERROR_BUILDID_MISMATCH = 0x805E0011L;

  public static final long NS_PROPTABLE_PROP_OVERWRITTEN = 0x5E000BL;

  public static final long NS_FINDBROADCASTER_NOT_FOUND = 0x5E000CL;

  public static final long NS_FINDBROADCASTER_FOUND = 0x5E000DL;

  public static final long NS_ERROR_XPATH_INVALID_ARG = 0x80070057L;

  public static final long NS_ERROR_XSLT_PARSE_FAILURE = 0x80600001L;

  public static final long NS_ERROR_XPATH_PARSE_FAILURE = 0x80600002L;

  public static final long NS_ERROR_XSLT_ALREADY_SET = 0x80600003L;

  public static final long NS_ERROR_XSLT_EXECUTION_FAILURE = 0x80600004L;

  public static final long NS_ERROR_XPATH_UNKNOWN_FUNCTION = 0x80600005L;

  public static final long NS_ERROR_XSLT_BAD_RECURSION = 0x80600006L;

  public static final long NS_ERROR_XSLT_BAD_VALUE = 0x80600007L;

  public static final long NS_ERROR_XSLT_NODESET_EXPECTED = 0x80600008L;

  public static final long NS_ERROR_XSLT_ABORTED = 0x80600009L;

  public static final long NS_ERROR_XSLT_NETWORK_ERROR = 0x8060000AL;

  public static final long NS_ERROR_XSLT_WRONG_MIME_TYPE = 0x8060000BL;

  public static final long NS_ERROR_XSLT_LOAD_RECURSION = 0x8060000CL;

  public static final long NS_ERROR_XPATH_BAD_ARGUMENT_COUNT = 0x8060000DL;

  public static final long NS_ERROR_XPATH_BAD_EXTENSION_FUNCTION = 0x8060000EL;

  public static final long NS_ERROR_XPATH_PAREN_EXPECTED = 0x8060000FL;

  public static final long NS_ERROR_XPATH_INVALID_AXIS = 0x80600010L;

  public static final long NS_ERROR_XPATH_NO_NODE_TYPE_TEST = 0x80600011L;

  public static final long NS_ERROR_XPATH_BRACKET_EXPECTED = 0x80600012L;

  public static final long NS_ERROR_XPATH_INVALID_VAR_NAME = 0x80600013L;

  public static final long NS_ERROR_XPATH_UNEXPECTED_END = 0x80600014L;

  public static final long NS_ERROR_XPATH_OPERATOR_EXPECTED = 0x80600015L;

  public static final long NS_ERROR_XPATH_UNCLOSED_LITERAL = 0x80600016L;

  public static final long NS_ERROR_XPATH_BAD_COLON = 0x80600017L;

  public static final long NS_ERROR_XPATH_BAD_BANG = 0x80600018L;

  public static final long NS_ERROR_XPATH_ILLEGAL_CHAR = 0x80600019L;

  public static final long NS_ERROR_XPATH_BINARY_EXPECTED = 0x8060001AL;

  public static final long NS_ERROR_XSLT_LOAD_BLOCKED_ERROR = 0x8060001BL;

  public static final long NS_ERROR_XPATH_INVALID_EXPRESSION_EVALUATED = 0x8060001CL;

  public static final long NS_ERROR_XPATH_UNBALANCED_CURLY_BRACE = 0x8060001DL;

  public static final long NS_ERROR_XSLT_BAD_NODE_NAME = 0x8060001EL;

  public static final long NS_ERROR_XSLT_VAR_ALREADY_SET = 0x8060001FL;

  public static final long NS_ERROR_XSLT_CALL_TO_KEY_NOT_ALLOWED = 0x80600020L;

  public static final long NS_XSLT_GET_NEW_HANDLER = 0x600001L;

  public static final long NS_ERROR_TRANSPORT_INIT = 0x80610001L;

  public static final long NS_ERROR_DUPLICATE_HANDLE = 0x80610002L;

  public static final long NS_ERROR_BRIDGE_OPEN_PARENT = 0x80610003L;

  public static final long NS_ERROR_BRIDGE_OPEN_CHILD = 0x80610004L;

  public static final long NS_ERROR_STORAGE_BUSY = 0x80630001L;

  public static final long NS_ERROR_STORAGE_IOERR = 0x80630002L;

  public static final long NS_ERROR_STORAGE_CONSTRAINT = 0x80630003L;

  public static final long NS_ERROR_DOM_FILE_NOT_FOUND_ERR = 0x80650000L;

  public static final long NS_ERROR_DOM_FILE_NOT_READABLE_ERR = 0x80650001L;

  public static final long NS_ERROR_DOM_INDEXEDDB_UNKNOWN_ERR = 0x80660001L;

  public static final long NS_ERROR_DOM_INDEXEDDB_NOT_FOUND_ERR = 0x80660003L;

  public static final long NS_ERROR_DOM_INDEXEDDB_CONSTRAINT_ERR = 0x80660004L;

  public static final long NS_ERROR_DOM_INDEXEDDB_DATA_ERR = 0x80660005L;

  public static final long NS_ERROR_DOM_INDEXEDDB_NOT_ALLOWED_ERR = 0x80660006L;

  public static final long NS_ERROR_DOM_INDEXEDDB_TRANSACTION_INACTIVE_ERR = 0x80660007L;

  public static final long NS_ERROR_DOM_INDEXEDDB_ABORT_ERR = 0x80660008L;

  public static final long NS_ERROR_DOM_INDEXEDDB_READ_ONLY_ERR = 0x80660009L;

  public static final long NS_ERROR_DOM_INDEXEDDB_QUOTA_ERR = 0x8066000BL;

  public static final long NS_ERROR_DOM_INDEXEDDB_VERSION_ERR = 0x8066000CL;

  public static final long NS_ERROR_DOM_INDEXEDDB_NOT_READABLE_ERR = 0x8066000DL;

  public static final long NS_ERROR_DOM_INDEXEDDB_KEY_ERR = 0x806603EAL;

  public static final long NS_ERROR_DOM_INDEXEDDB_RENAME_OBJECT_STORE_ERR = 0x806603EBL;

  public static final long NS_ERROR_DOM_INDEXEDDB_RENAME_INDEX_ERR = 0x806603ECL;

  public static final long NS_ERROR_DOM_FILEHANDLE_UNKNOWN_ERR = 0x80670001L;

  public static final long NS_ERROR_DOM_FILEHANDLE_NOT_ALLOWED_ERR = 0x80670002L;

  public static final long NS_ERROR_DOM_FILEHANDLE_INACTIVE_ERR = 0x80670003L;

  public static final long NS_ERROR_DOM_FILEHANDLE_ABORT_ERR = 0x80670004L;

  public static final long NS_ERROR_DOM_FILEHANDLE_READ_ONLY_ERR = 0x80670005L;

  public static final long NS_ERROR_DOM_FILEHANDLE_QUOTA_ERR = 0x80670006L;

  public static final long NS_ERROR_SIGNED_JAR_NOT_SIGNED = 0x80680001L;

  public static final long NS_ERROR_SIGNED_JAR_MODIFIED_ENTRY = 0x80680002L;

  public static final long NS_ERROR_SIGNED_JAR_UNSIGNED_ENTRY = 0x80680003L;

  public static final long NS_ERROR_SIGNED_JAR_ENTRY_MISSING = 0x80680004L;

  public static final long NS_ERROR_SIGNED_JAR_WRONG_SIGNATURE = 0x80680005L;

  public static final long NS_ERROR_SIGNED_JAR_ENTRY_TOO_LARGE = 0x80680006L;

  public static final long NS_ERROR_SIGNED_JAR_ENTRY_INVALID = 0x80680007L;

  public static final long NS_ERROR_SIGNED_JAR_MANIFEST_INVALID = 0x80680008L;

  public static final long NS_ERROR_DOM_FILESYSTEM_INVALID_PATH_ERR = 0x80690001L;

  public static final long NS_ERROR_DOM_FILESYSTEM_INVALID_MODIFICATION_ERR = 0x80690002L;

  public static final long NS_ERROR_DOM_FILESYSTEM_NO_MODIFICATION_ALLOWED_ERR = 0x80690003L;

  public static final long NS_ERROR_DOM_FILESYSTEM_PATH_EXISTS_ERR = 0x80690004L;

  public static final long NS_ERROR_DOM_FILESYSTEM_TYPE_MISMATCH_ERR = 0x80690005L;

  public static final long NS_ERROR_DOM_FILESYSTEM_UNKNOWN_ERR = 0x80690006L;

  public static final long NS_ERROR_SIGNED_APP_MANIFEST_INVALID = 0x806B0001L;

  public static final long NS_ERROR_DOM_PUSH_DENIED_ERR = 0x806D0002L;

  public static final long NS_ERROR_DOM_PUSH_ABORT_ERR = 0x806D0003L;

  public static final long NS_ERROR_DOM_PUSH_SERVICE_UNREACHABLE = 0x806D0004L;

  public static final long NS_ERROR_DOM_PUSH_INVALID_KEY_ERR = 0x806D0005L;

  public static final long NS_ERROR_DOM_PUSH_MISMATCHED_KEY_ERR = 0x806D0006L;

  public static final long NS_ERROR_DOM_MEDIA_ABORT_ERR = 0x806E0001L;

  public static final long NS_ERROR_DOM_MEDIA_NOT_ALLOWED_ERR = 0x806E0002L;

  public static final long NS_ERROR_DOM_MEDIA_NOT_SUPPORTED_ERR = 0x806E0003L;

  public static final long NS_ERROR_DOM_MEDIA_DECODE_ERR = 0x806E0004L;

  public static final long NS_ERROR_DOM_MEDIA_FATAL_ERR = 0x806E0005L;

  public static final long NS_ERROR_DOM_MEDIA_METADATA_ERR = 0x806E0006L;

  public static final long NS_ERROR_DOM_MEDIA_OVERFLOW_ERR = 0x806E0007L;

  public static final long NS_ERROR_DOM_MEDIA_END_OF_STREAM = 0x806E0008L;

  public static final long NS_ERROR_DOM_MEDIA_WAITING_FOR_DATA = 0x806E0009L;

  public static final long NS_ERROR_DOM_MEDIA_CANCELED = 0x806E000AL;

  public static final long NS_ERROR_DOM_MEDIA_MEDIASINK_ERR = 0x806E000BL;

  public static final long NS_ERROR_DOM_MEDIA_DEMUXER_ERR = 0x806E000CL;

  public static final long NS_ERROR_DOM_MEDIA_CDM_ERR = 0x806E000DL;

  public static final long NS_ERROR_DOM_MEDIA_NEED_NEW_DECODER = 0x806E000EL;

  public static final long NS_ERROR_DOM_MEDIA_INITIALIZING_DECODER = 0x806E000FL;

  public static final long NS_ERROR_DOM_MEDIA_REMOTE_CRASHED_RDD_OR_GPU_ERR = 0x806E0010L;

  public static final long NS_ERROR_DOM_MEDIA_REMOTE_CRASHED_UTILITY_ERR = 0x806E0011L;

  public static final long NS_ERROR_DOM_MEDIA_REMOTE_CRASHED_MF_CDM_ERR = 0x806E0012L;

  public static final long NS_ERROR_DOM_MEDIA_KEY_QUOTA_EXCEEDED_ERR = 0x806E001EL;

  public static final long NS_ERROR_DOM_MEDIA_SOURCE_MAX_BUFFER_QUOTA_EXCEEDED_ERR = 0x806E001FL;

  public static final long NS_ERROR_DOM_MEDIA_SOURCE_FULL_BUFFER_QUOTA_EXCEEDED_ERR = 0x806E0020L;

  public static final long NS_ERROR_DOM_MEDIA_CDM_NO_SESSION_ERR = 0x806E0032L;

  public static final long NS_ERROR_DOM_MEDIA_CDM_SESSION_OPERATION_ERR = 0x806E0033L;

  public static final long NS_ERROR_DOM_MEDIA_CDM_HDCP_NOT_SUPPORT = 0x806E0034L;

  public static final long NS_ERROR_DOM_MEDIA_CDM_NOT_FOUND_ERR = 0x806E0035L;

  public static final long NS_ERROR_DOM_MEDIA_CUBEB_INITIALIZATION_ERR = 0x806E0065L;

  public static final long NS_ERROR_DOM_MEDIA_EXTERNAL_ENGINE_NOT_SUPPORTED_ERR = 0x806E0066L;

  public static final long NS_ERROR_DOM_MEDIA_CDM_PROXY_NOT_SUPPORTED_ERR = 0x806E0067L;

  public static final long NS_ERROR_DOM_MEDIA_DENIED_IN_NON_UTILITY = 0x806E0068L;

  public static final long NS_ERROR_DOM_MEDIA_RANGE_ERR = 0x806E0069L;

  public static final long NS_ERROR_DOM_MEDIA_TYPE_ERR = 0x806E006AL;

  public static final long NS_ERROR_DOM_MEDIA_MEDIA_ENGINE_INITIALIZATION_ERR = 0x806E006BL;

  public static final long NS_ERROR_DOM_MEDIA_DROPPED_BY_ENCODER_ERR = 0x806E006CL;

  public static final long NS_ERROR_UC_UPDATE_UNKNOWN = 0x806F0001L;

  public static final long NS_ERROR_UC_UPDATE_DUPLICATE_PREFIX = 0x806F0002L;

  public static final long NS_ERROR_UC_UPDATE_INFINITE_LOOP = 0x806F0003L;

  public static final long NS_ERROR_UC_UPDATE_WRONG_REMOVAL_INDICES = 0x806F0004L;

  public static final long NS_ERROR_UC_UPDATE_CHECKSUM_MISMATCH = 0x806F0005L;

  public static final long NS_ERROR_UC_UPDATE_MISSING_CHECKSUM = 0x806F0006L;

  public static final long NS_ERROR_UC_UPDATE_SHUTDOWNING = 0x806F0007L;

  public static final long NS_ERROR_UC_UPDATE_TABLE_NOT_FOUND = 0x806F0008L;

  public static final long NS_ERROR_UC_UPDATE_BUILD_PREFIX_FAILURE = 0x806F0009L;

  public static final long NS_ERROR_UC_UPDATE_FAIL_TO_WRITE_DISK = 0x806F000AL;

  public static final long NS_ERROR_UC_UPDATE_UNEXPECTED_VERSION = 0x806F000BL;

  public static final long NS_ERROR_UC_PARSER_MISSING_PARAM = 0x806F000CL;

  public static final long NS_ERROR_UC_PARSER_DECODE_FAILURE = 0x806F000DL;

  public static final long NS_ERROR_UC_PARSER_UNKNOWN_THREAT = 0x806F000EL;

  public static final long NS_ERROR_UC_PARSER_MISSING_VALUE = 0x806F000FL;

  public static final long NS_ERROR_INTERNAL_ERRORRESULT_JS_EXCEPTION = 0x80700001L;

  public static final long NS_ERROR_INTERNAL_ERRORRESULT_DOMEXCEPTION = 0x80700002L;

  public static final long NS_ERROR_INTERNAL_ERRORRESULT_EXCEPTION_ON_JSCONTEXT = 0x80700003L;

  public static final long NS_ERROR_INTERNAL_ERRORRESULT_TYPEERROR = 0x80700004L;

  public static final long NS_ERROR_INTERNAL_ERRORRESULT_RANGEERROR = 0x80700005L;

  public static final long NS_ERROR_WDBA_NO_PROGID = 0x80720001L;

  public static final long NS_ERROR_WDBA_HASH_CHECK = 0x80720002L;

  public static final long NS_ERROR_WDBA_REJECTED = 0x80720003L;

  public static final long NS_ERROR_WDBA_BUILD = 0x80720004L;

  public static final long NS_ERROR_DOM_QM_CLIENT_INIT_ORIGIN_UNINITIALIZED = 0x80730001L;

  public static final long NS_ERROR_CLIPBOARD_TOO_BIG = 0x80740001L;

  public static final long NS_ERROR_DOM_SERIAL_PARITY_ERROR = 0x80750001L;

  public static final long NS_ERROR_DOWNLOAD_COMPLETE = 0x80780001L;

  public static final long NS_ERROR_DOWNLOAD_NOT_PARTIAL = 0x80780002L;

  public static final long NS_ERROR_UNORM_MOREOUTPUT = 0x80780021L;

  public static final long NS_ERROR_DOCSHELL_REQUEST_REJECTED = 0x807803E9L;

  public static final long NS_ERROR_DOCUMENT_IS_PRINTMODE = 0x807807D1L;

  public static final long NS_SUCCESS_DONT_FIXUP = 0x780001L;

  public static final long NS_SUCCESS_RESTART_APP = 0x780001L;

  public static final long NS_ERROR_NOT_IN_TREE = 0x80780026L;

  public static final long NS_OK_NO_NAME_CLAUSE_HANDLED = 0x780022L;

  public static final long NS_ERROR_BLOCKED_BY_POLICY = 0x80780003L;

}