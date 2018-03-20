#region Using

using System.Net;
using System.Net.Mail;
using System.Threading;
using Nimble.Business.Library.Common;

#endregion Using

namespace Nimble.Business.Engine.Common
{
    public class MailManager
    {
        #region Public Members

        #region Properties

        public MailContext MailContext { get; set; }

        #endregion Properties

        #region Methods

        public FaultExceptionDetail Send(MailMessage mailMessage)
        {
            if (MailContext == null)
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.OBJECT_NULL_INSTANCE, "Mail context"));
            }
            if (string.IsNullOrEmpty(MailContext.Host))
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.OBJECT_NOT_DEFINED, "Host"));
            }
            if (string.IsNullOrEmpty(MailContext.UserName))
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.OBJECT_NOT_DEFINED, "User name"));
            }
            if (string.IsNullOrEmpty(MailContext.Password))
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.OBJECT_NOT_DEFINED, "Password"));
            }
            var faultExceptionDetail = new FaultExceptionDetail();
            if (mailMessage == null)
            {
                throw FaultExceptionDetail.Create(new FaultExceptionDetail(Constants.OBJECT_NULL_INSTANCE, "Mail message"));
            }
            var smtpClient = new SmtpClient(MailContext.Host, MailContext.Port)
            {
                EnableSsl = MailContext.EnableSsl,
                UseDefaultCredentials = MailContext.UseDefaultCredentials,
                Timeout = MailContext.Timeout
            };
            smtpClient.Credentials = new NetworkCredential(MailContext.UserName, MailContext.Password);
            try
            {
                smtpClient.Send(mailMessage);
            }
            catch (SmtpFailedRecipientsException exception)
            {
                foreach (var smtpFailedRecipientException in exception.InnerExceptions)
                {
                    if (smtpFailedRecipientException.StatusCode != SmtpStatusCode.MailboxBusy &&
                        smtpFailedRecipientException.StatusCode != SmtpStatusCode.MailboxUnavailable) continue;
                    Thread.Sleep(MailContext.FailedTimeout);
                    try
                    {
                        mailMessage.To.Clear();
                        mailMessage.To.Add(smtpFailedRecipientException.FailedRecipient);
                        smtpClient.Send(mailMessage);
                    }
                    catch (SmtpFailedRecipientsException smtpFailedRecipientsException)
                    {
                        faultExceptionDetail.Items.Add(new FaultExceptionDetail(smtpFailedRecipientsException.Message));
                    }
                }
            }
            return faultExceptionDetail;
        }

        public FaultExceptionDetail Send(string subject, string body, string recipients)
        {
            var mailMessage = new MailMessage(MailContext.UserName, recipients, subject, body);
            return Send(mailMessage);
        }

        #endregion Methods

        #endregion Public Members
    }
}