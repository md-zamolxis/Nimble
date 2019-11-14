#region Usings

#endregion Usings

namespace Nimble.Business.Library.Common
{
    public sealed class Constants
    {
        public const char QUOTE = '\'';
        public const char SEMICOLON = ';';
        public const char POINT = '.';
        public const char COMMA = ',';
        public const char PERCENT = '%';
        public const char LINE_FEED = '\n';
        public const char LEFT_BRACE = '{';
        public const char RIGHT_BRACE = '}';
        public const char SLASH_DELIMITER = '/';
        public const char UNDERSCORE = '_';

        public const string EMAIL_VALIDATION_PATTERN = @"\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w+([-.]\w+)*";
        public const string IP_VALIDATION_PATTERN = @"^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$";
        public const string BASE64_VALIDATION_PATTERN = @"^[a-zA-Z0-9\+/]*={0,3}$";
        public const string IP_INFO_FORMAT = "IP {0} belongs to block ({1}, {2}) of location with: code - {3}; country - {4}; region - {5}; city - {6}; postal code - {7}; latitude - {8}; longitude - {9}; metro code - {10}; area code - {11}";
        public const string EXCEPTION_LOG_FORMAT = "<br>Source: {0} <br>Message: {1} <br>Stack trace: {2} <br>Inner: {3}";
        public const string SECURITY_VIOLATION_ENTITY_INVALID = "Security violation - invalid {0}.";
        public const string SECURITY_VIOLATION_ENTITY_MISSED = "Security violation - missing {0}.";
        public const string SECURITY_VIOLATION_ENTITY_DIFFERENT = "{0} security violation - {1} are different.";
        public const string SECURITY_SESSION_PATTERN = "Emplacement: {0} Application: {1} Session: {2}";
        public const string FORWARDED_IP_ADDRESS = "HTTP_X_FORWARDED_FOR";
        public const string REMOTE_IP_ADDRESS = "REMOTE_ADDR";
        public const string REMOTE_PORT = "REMOTE_PORT";
        public const string OBJECT_NULL_INSTANCE = "[{0}] object null instance.";
        public const string OBJECT_NOT_DEFINED = "[{0}] not defined.";
        public const string SQL_INSERT_ERROR_GENERIC_MESSAGE = "INSERT";
        public const string SQL_UPDATE_ERROR_GENERIC_MESSAGE = "UPDATE";
        public const string SQL_DELETE_ERROR_GENERIC_MESSAGE = "DELETE";
        public const string SQL_VIOLATION_ERROR_GENERIC_MESSAGE = "Violation";
        public const string SQL_UNMATCHED_OR_NOT_FOUND_ENTITY_MESSAGE = "Entity not found or unmatched entity version - data was changed or removed from the previous read.";
        public const string SQL_ENTITY_PROPERTIES_NOT_UNIQUE_OR_NOT_VALID_MESSAGE = "Entity properties not unique or not valid (original message - [{0}]).";
        public const string MASTER_DATABASE_NAME = "master";
        public const string NUMERIC_SYMBOLS = "0123456789";
        public const string XML_ILLEGAL_CHARACTERS = @"[\u0000-\u0008\u000B\u000C\u000E-\u001F]";
        public const string XML_ARRAY_TAG = "<ArrayOf{0}>{1}</ArrayOf{0}>";
        public const string STRING_CODE_MAX_WARNING = "[{0}] not valid - maximum string length must be less or equal than {1} symbols ([{2}]).";
        public const string BUSINESS_RULE_UNHANDLED_ERROR = "Business rule error - see application log for details.";
        public const string UNHANDLED_ERROR = "An unhandled error has occurred - [{0}].";
        public const string ENTITY_ACCESS_DENIED = "Current {0} [{1}] does not has administrative permissions.";
        public const string CSV_REGEX_EXPRESSION = "((?([\\x22])(?:[\\x22])(?<Column>[^\\x22]*)(?:[\\x22])|(?<Column>[^,\r\n]*]*))(?:,?))+(?:$|[\r\n]{0,2})";
        public const string CSV_COLUMN_NAME = "Column";
        public const string XML_NAMESPACE_ATTRIBUTE_NAME = "xmlns";
        public const string ENTITY_ADDED = "{0} entity [{1}] added.";
        public const string ENTITY_UPDATED = "{0} entity [{1}] updated.";
        public const string ENTITY_REMOVED = "{0} entity [{1}] removed.";
        public const string TEMPORARY_DATA_FILE_PATH = "{0}{1}{2}";
        public const string JSON_HTTP_MODULE_REQUEST_BODY_KEY = "JsonHttpModule.RequestBodyKey";

        public const int EVENT_LOG_MESSAGE_LENGTH = 32766;

        public const int BINARY_BASE = 2;
        public const string BINARY_VALIDATION_PATTERN = "^[01]+$";
        public const int BINARY_LENGTH = 128;
        public const char BINARY_LEADING_CHAR = '0';

        public const int DEFAULT_IMAGE_WIDTH = 800;
        public const int DEFAULT_IMAGE_HEIGHT = 600;
        public const int STRING_CODE_MAX_LENGTH = 200;

        public const string DECIMAL_FORMAT = "0.000000000";
    }
}